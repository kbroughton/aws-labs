#!/bin/bash

usage='	
		Deletes the user, group, and role that were created for the lab,
		detaching and deleting all the policies.
		It also removes the env.sh, update_iam_policy_*, keys.json and kingme.zip files.
		'


if [ x$1 != x ]; then
    if [ $1 == "help" ] || [ $1 == "--help" ]; then
      echo "${usage}"
      exit 0
	fi
fi

echo '
		Deleting...
'

./create_group.sh --delete

source env.sh

#Detach the administrator policy from the user, delete its access keys and finally the user itself
aws iam detach-user-policy --user-name $USER_NAME --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam delete-access-key --user-name $USER_NAME --access-key-id `cat keys.json | jq -r '.AccessKey.AccessKeyId'`
aws iam delete-user --user-name $USER_NAME

#Detach the role policy, and delete them both
aws iam detach-role-policy --role-name $DISCOVERED_ROLE_NAME --policy-arn $POLICY_ARN
aws iam delete-role --role-name $DISCOVERED_ROLE_NAME
aws iam delete-policy --policy-arn $POLICY_ARN

#Delete the lambda function
aws lambda delete-function --function-name kingme-$RAND

#Remove the files that need to be recreated every time the lab runs
rm update_iam_policy_*
rm env.sh
rm kingme.zip
rm keys.json

echo '
		Done!
'
