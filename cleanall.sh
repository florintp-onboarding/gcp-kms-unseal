# Cleanup

[[ "X$PROJID" == "X" ]] || exit

gcloud -q iam service-accounts keys list \
--iam-account=$SACC'@'${PROJID}'.iam.gserviceaccount.com'

terraform destroy -auto-approve

#for i in $(gcloud iam service-accounts keys list --iam-account=$SACC'@'${PROJID}'.iam.gserviceaccount.com'|grep -v 'KEY_ID'|awk '{print $1}') ; do 
#    gcloud -q iam service-accounts keys delete $i --iam-account=$SACC'@'${PROJID}'.iam.gserviceaccount.com'
#done

[[ "X$PROJID" == "X" ]] || gcloud iam service-accounts delete \
$SACC'@'${PROJID}'.iam.gserviceaccount.com'

touch gcloud-vault-test.json terraform.tfvars
rm -f terraform.tfstate terraform.tfstate.backup

