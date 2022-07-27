[![license](http://img.shields.io/badge/license-apache_2.0-red.svg?style=flat)](https://github.com/florintp-onboarding/generate-root-tokens-using-unseal-keys/edit/main/LICENSE)

# The scope of this repository is to provide the steps for deploying Vault with Auto-unseal using KMS in GCP 

These assets are provided to perform the tasks described in the [Auto-unseal with Google Cloud
KMS](https://learn.hashicorp.com/vault/operations/autounseal-gcp-kms) guide and adapted for a workout example.


![](https://github.com/florintp-onboarding/gcp-kms-unseal/blob/d731afa81d497ca86640250406ce04b09fc9c342/diagram/main_diagram.png)

----

# Which are the main tools used to accomplish this task?
----
# Vault
-	Website: https://www.vaultproject.io
-	Announcement list: [Google Groups](https://groups.google.com/group/hashicorp-announce)
-	Discussion forum: [Discuss](https://discuss.hashicorp.com/c/vault)
- Documentation: [https://www.vaultproject.io/docs/](https://www.vaultproject.io/docs/)
- Tutorials: [HashiCorp's Learn Platform](https://learn.hashicorp.com/vault)
- Certification Exam: [Vault Associate](https://www.hashicorp.com/certification/#hashicorp-certified-vault-associate)

<img width="300" alt="Vault Logo" src="https://github.com/hashicorp/vault/blob/f22d202cde2018f9455dec755118a9b84586e082/Vault_PrimaryLogo_Black.png">

----
Vault is a tool for securely accessing secrets. A secret is anything that you want to tightly control access to, such as API keys, passwords, certificates, and more. Vault provides a unified interface to any secret, while providing tight access control and recording a detailed audit log.

----
**Please note**: We take Vault's security and our users' trust very seriously. If you believe you have found a security issue in Vault, _please responsibly disclose_ by contacting us at [security@hashicorp.com](mailto:security@hashicorp.com).

----
# Terraform
- Website: https://www.terraform.io
- Forums: [HashiCorp Discuss](https://discuss.hashicorp.com/c/terraform-core)
- Documentation: [https://www.terraform.io/docs/](https://www.terraform.io/docs/)
- Tutorials: [HashiCorp's Learn Platform](https://learn.hashicorp.com/terraform)
- Certification Exam: [HashiCorp Certified: Terraform Associate](https://www.hashicorp.com/certification/#hashicorp-certified-terraform-associate)

<img alt="Terraform" src="https://www.datocms-assets.com/2885/1629941242-logo-terraform-main.svg" width="400px">

----
Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers as well as custom in-house solutions.

----

# What is needed to follow this guide?
- Install [Terraform](https://www.terraform.io/downloads).
- Install [Vault client](https://www.vaultproject.io/downloads) -  enables the option to test access of vault server from local system.
- Install the [gcloud CLI](https://cloud.google.com/sdk/docs/install), configure and enable Cloud Key Management Service [KMS](https://console.developers.google.com/apis/api/cloudkms.googleapis.com/overview?project=<PROJECTID>) API.
- Install [gh](https://cli.github.com/manual/installation).
* At least 2 variables must be present into environment in order to make the procedure valid: PROJID and SACC.
Those 2 variables must be loaded into environment prior to continue this workout example.
In this case, a sourced file, variables-kms-unseal.source, with the correct values mut be provided in the upper directory hierarchy.

- Enable KMS API for project number.
- For example, PROJNAME=$(gcloud projects describe $PROJID  --format json|jq -c '.projectNumber')  && eval PROJNAME=$PROJNAME
gcloud services enable cloudkms.googleapis.com

# Which are the steps?
For all commands in one go, execute the shell snip [create_and_unseal_vault.sh](https://github.com/florintp-onboarding/gcp-kms-unseal/blob/main/create_and_unseal_vault.sh) having as default the creation of the KMS keyring and unseal key.

1. Set this location as your working directory
```shell
gh repo clone florintp-onboarding/gcp-kms-unseal
```

2. Use the  GCP account information in the 'terraform-without-keyring.tfvars' and save it as 'terraform.tfvars'. This will change on creation of a new project!
Complete the variables in ../variables-kms-unseal.source.
PROJID - for project id
SACC - for service account 

3. Load the default variables
``` shell
source ../variables-kms-unseal.source
```

4. Create a serviceAccount and generate the JSON key using the [IAM-Admin](https://console.cloud.google.com/iam-admin/serviceaccounts) and [Enable IAM API](https://cloud.google.com/iam/docs/granting-changing-revoking-access?hl=en_US)
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

ln -s service_account-$SACC-key.json gcloud-vault-test1.json
cat terraform.tfvars.example|egrep -v 'key_ring|crypto_key|keyring_location' | sed  "s/<PROJECT_ID>/$PROJID/g ; s/<ACCOUNT_FILE_PATH>/\.\/gcloud-vault-test1.json/g" > terraform.tfvars
echo 'key_ring = "test"' >> terraform.tfvars
echo  'crypto_key = "vault-test1"' >> terraform.tfvars
echo  'keyring_location = "global"' >> terraform.tfvars
```

9. Create infrastructure using Terraform
* initialize working directory
```shell
terraform init
```
* plan, to see what resources will be created
```shell
terraform plan
```
* create resources
```shell
terraform apply -auto-approve
```
* observe the information output after execution of the terraform plan
```shell
terraform output
```

10. [Connecting to the compute instance](https://cloud.google.com/compute/docs/instances/connecting-to-instance)
```shell
eval  $(terraform output|egrep '^nodename|^zone'|sed "s/ //g")
gcloud -q compute ssh  --zone=${zone} ${nodename} --project ${PROJID}
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

12.  Explore the Vault configuration file on the compute node
```shell
cat /test/vault/config.hcla
```

13. (On a different terminal window) Rotate key and see that the vault is still able to unseal. A manual rotation of the key may be executed from GGP Console:
```shell
gcloud kms keys update vault-test1 \
--location global \
--keyring test \
--rotation-period 2d \
--next-rotation-time 1d
```

14. Cleanup may be performed step by step or in one go by simply executing the shell snip [cleanall.sh](https://github.com/florintp-onboarding/gcp-kms-unseal/blob/main/cleanall.sh).
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
