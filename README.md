# Vault Auto-unseal using GCP Cloud KMS

These assets are provided to perform the tasks described in the [Auto-unseal with Google Cloud
KMS](https://learn.hashicorp.com/vault/operations/autounseal-gcp-kms) guide and adapted for a workout example.

# Prerequisites:
* Install Terraform (https://www.terraform.io/downloads).
* Install Vault client (https://www.vaultproject.io/downloads) - it is a nice to have option for testing access of vault server from local system.
* Install the gcloud CLI and configure (https://cloud.google.com/sdk/docs/install) and enable Cloud Key Management Service [KMS] API (https://console.developers.google.com/apis/api/cloudkms.googleapis.com/overview?project=<PROJECTID>)
* Install gh (https://cli.github.com/manual/installation).
* At least 2 variables must be present into environment in order to make the procedure valid: PROJID and SACC.
Those 2 variables must be loaded into environment prior to continue this workout example.
In this case, a sourced file, variables-kms-unseal.source, with the correct values provided in the upper directory hierarchy.

* Enable KMS API for project number. PROJNAME=$(gcloud projects describe $PROJID  --format json|jq -c '.projectNumber')  && eval PROJNAME=$PROJNAME
gcloud services enable cloudkms.googleapis.com

 
For all commands in one go you may simply execute the shell snip (https://github.com/florintp-onboarding/gcp-kms-unseal/blob/main/create_and_unseal_vault.sh)

1. Set this location as your working directory
```shell
gh repo clone florintp-onboarding/gcp-kms-unseal
```

2. Use the  GCP account information in the 'terraform-without-keyring.tfvars' and save it as 'terraform.tfvars'. This will change on creation of a new project!
Complete the variables in ../variables-kms-unseal.source.
PROJID - for project id
SACC - for service account 

3. Load the default variable
``` shell
source ../variables-kms-unseal.source
```
4. Create a serviceAccount and generate the JSON key. If the Project_ID=hc-6b43a5a31f54432b9a6159440bb then the link for creating the serviceAccount is at [IAM-Admin] (https://console.cloud.google.com/iam-admin/serviceaccounts). [Enable IAM API] (https://cloud.google.com/iam/docs/granting-changing-revoking-access?hl=en_US)
```shell

gcloud -q iam service-accounts create $SACC \
--description="Vault Service Account" \
--display-name="$SACC"
```

5.  List all the service accounts
``` shell
 gcloud -q iam service-accounts list
```

6. Generate the JSON key
```shell
gcloud -q iam service-accounts keys create service_account-$SACC-key.json \
--iam-account=$SACC'@'${PROJID}'.iam.gserviceaccount.com'
```

7. Check the key list
```shell
gcloud -q iam service-accounts keys list \
--iam-account=$SACC'@'${PROJID}'.iam.gserviceaccount.com'
```

8. Add rol-bindings to the service account
```shell
[[ "X$PROJID" == "X" ]] ||gcloud -q projects add-iam-policy-binding  $PROJID \
--member='serviceAccount:'$SACC'@'${PROJID}'.iam.gserviceaccount.com' \
--role='roles/editor'

[[ "X$PROJID" == "X" ]] || gcloud -q projects add-iam-policy-binding  $PROJID \
--member='serviceAccount:'$SACC'@'${PROJID}'.iam.gserviceaccount.com' \
--role='roles/compute.admin'

[[ "X$PROJID" == "X" ]] || gcloud -q projects add-iam-policy-binding  $PROJID \
--member='serviceAccount:'$SACC'@'${PROJID}'.iam.gserviceaccount.com' \
--role='roles/cloudkms.admin'

# At first RUN, the keyring and key must be created
cp main.tf_with_key_creation main.tf

# After keyring already present
# cp main.tf_without_key_creation main.tf

ln -s service_account-$SACC-key.json  gcloud-vault-test1.json
cat terraform.tfvars.example|egrep -v 'key_ring|crypto_key|keyring_location' | sed  "s/<PROJECT_ID>/$PROJID/g ; s/<ACCOUNT_FILE_PATH>/\.\/gcloud-vault-test1.json/g" > terraform.tfvars
echo 'key_ring = "test"' >> terraform.tfvars
echo  'crypto_key = "vault-test1"' >> terraform.tfvars
echo  'keyring_location = "global"' >> terraform.tfvars
```

9. Terraform prepare and steps
```shell
terraform init
terraform plan
terraform apply -auto-approve
```

10. [SSH into the compute instance](https://cloud.google.com/compute/docs/instances/connecting-to-instance)
```shell
 export instance_id=$(terraform output vault_server_instance_id)
 export zone_name=$(terraform output zone|sed "s/\"//g") ; export node_name=$(terraform output nodename|sed "s/\"//g") ; \
 gcloud -q compute ssh  --zone=${zone_name} ${node_name} --project ${PROJID}
```

11.  Check the Vault server status
```shell
sudo VAULT_ADDR=127.0.0.1:8200 vault status
sudo VAULT_ADDR=127.0.0.1:8200 vault operator init
sudo VAULT_ADDR=127.0.0.1:8200 vault status
sudo systemctl stop vault
sudo systemctl start vault
sudo systemctl status vault
sudo VAULT_ADDR=127.0.0.1:8200 vault status
```

12.  Explorer the Vault configuration file
```shell
cat /test/vault/config.hcla
```

13. (On a differnt terminal window) Rotate key and see that the vault is still able to unseal. A manual rotation of the key may be executed from Google Cloud Console:
```shell
gcloud kms keys update vault-test1 \
--location global \
--keyring test \
--rotation-period 2d \
--next-rotation-time 1d
```

14. Cleanup may be performed step by step or in one go by simply executing the shell snip (https://github.com/florintp-onboarding/gcp-kms-unseal/blob/main/cleanall.sh)
```shell
terraform destroy -auto-approve

for i in $(gcloud iam service-accounts keys list --iam-account=$SACC'@'${PROJID}'.iam.gserviceaccount.com'|grep -v 'KEY_ID'|awk '{print $1}') ; do 
    gcloud -q iam service-accounts keys delete $i --iam-account=$SACC'@'${PROJID}'.iam.gserviceaccount.com'
done

rm -f terraform.tfstate terraform.tfstate.backup gcloud-vault-test1.json
```

15. Delete the serviceAccount
```shell
[[ "X$PROJID" == "X" ]] || gcloud -q iam service-accounts delete \
$SACC'@'${PROJID}'.iam.gserviceaccount.com'
```
