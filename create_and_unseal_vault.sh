source ../variables-kms-unseal.source

gcloud -q iam service-accounts create $SACC \
--description="Vault Service Account" \
--display-name="$SACC"

gcloud -q iam service-accounts list


gcloud -q iam service-accounts keys create service_account-$SACC-key.json \
--iam-account=$SACC'@'${PROJID}'.iam.gserviceaccount.com'

gcloud -q iam service-accounts keys list \
--iam-account=$SACC'@'${PROJID}'.iam.gserviceaccount.com'

[[ "X$PROJID" == "X" ]] ||gcloud -q projects add-iam-policy-binding  $PROJID \
--member='serviceAccount:'$SACC'@'${PROJID}'.iam.gserviceaccount.com' \
--role='roles/editor'

[[ "X$PROJID" == "X" ]] || gcloud -q projects add-iam-policy-binding  $PROJID \
--member='serviceAccount:'$SACC'@'${PROJID}'.iam.gserviceaccount.com' \
--role='roles/compute.admin'

[[ "X$PROJID" == "X" ]] || gcloud -q projects add-iam-policy-binding  $PROJID \
--member='serviceAccount:'$SACC'@'${PROJID}'.iam.gserviceaccount.com' \
--role='roles/cloudkms.admin'

# At first RUN
#cp main.tf_with_key_creation main.tf

# After keyring already present
cp main.tf_without_key_creation main.tf

ln -s service_account-$SACC-key.json  gcloud-vault-test1.json
cat terraform.tfvars.example|egrep -v 'key_ring|crypto_key|keyring_location' | sed  "s/<PROJECT_ID>/$PROJID/g ; s/<ACCOUNT_FILE_PATH>/\.\/gcloud-vault-test1.json/g" > terraform.tfvars
echo 'key_ring = "test"' >> terraform.tfvars
echo  'crypto_key = "vault-test1"' >> terraform.tfvars
echo  'keyring_location = "global"' >> terraform.tfvars

terraform init
terraform plan
terraform apply -auto-approve

export instance_id=$(terraform output vault_server_instance_id)
export zone_name=$(terraform output zone|sed "s/\"//g") ; export node_name=$(terraform output nodename|sed "s/\"//g") ; \
gcloud -q compute ssh  --zone=${zone_name} ${node_name} --project ${PROJID}

