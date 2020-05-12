#!/bin/bash

# Create the roles and policies to simulate a discovered high-privileged role which our user/attacker can attach to the lambda

usage='
		setup.sh [AWS_PROFILE]
		Stores the random string used as a suffix to all AWS resource names.
		Copies sample-env.sh to env.sh which is .gitignored
		Creates a random variable in env.sh and set AWS_PROFILE is passed.
		AWS_PROFILE must have admin permissions.
		Creates the policies and roles with the mistaken use of NotAction
'

echo '
		WARNING: This script creates a user with prefix marketing-dave, which is insecure, for demonstration purposes.
		Be sure to delete everything afterwards by running the delete.sh script
'


PROJECT_TAG='{ "Key":"project", "Value":"LAB_1_Lambda" }'

#Check if env.sh exists, and if it doesn't, copy it from sample-env.sh
if [[ ! -f env.sh ]];then
  cp sample-env.sh env.sh
fi 

#Function that sets variables

function set_var(){
    varname=$1
    varvalue=$2
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        sed -i "s|$varname=$|$varname=$varvalue|" env.sh
			# Unix
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|$varname=$|$varname=$varvalue|" env.sh
            # Mac OSX
    else
        echo "os $OSTYPE not supported"
        exit 1
        # POSIX compatibility layer and Linux environment emulation for Windows
    fi
}

#Check that jq is installed

JQ_PATH=`which jq || ""`
if [[ x${JQ_PATH}x == xx ]]; then
 echo "please install jq.  Aborting"
 exit 1
fi

# Allow caller of script to pass in over-riding AWS_PROFILE or "help"
if [ x$1 != x ]; then
    if [ $1 == "help" ] || [ $1 == "--help" ]; then
      echo "${usage}"
      exit 0
    fi
    ARG_AWS_PROFILE=$1
    set_var AWS_PROFILE $ARG_AWS_PROFILE
else
    # Set the profile from the current ENV var. If unset, aws-cli uses 'default'.
    set_var AWS_PROFILE $AWS_PROFILE
fi

source env.sh

if [ x${RAND}x == xx ]; then
   RAND=$RANDOM
   set_var RAND $RAND
fi

#Gets account ID and sets variables
AWS_ACCOUNT_ID=`aws sts get-caller-identity | jq -r '.Account'`

if [ x${AWS_ACCOUNT_ID}x == xx ]; then
   echo "Could not get AWS_ACCOUNT_ID. Check your creds with aws sts get-caller-identity"
   exit 1
else
   set_var AWS_ACCOUNT_ID $AWS_ACCOUNT_ID
   echo "using AWS_ACCOUNT_ID $AWS_ACCOUNT_ID"
   POLICY_NAME=update_iam_policy_${RAND}
   set_var USER_NAME marketing-dave-${RAND}
   set_var POLICY_NAME $POLICY_NAME
   set_var DISCOVERED_ROLE_NAME discovered-role-with-iam-privs-${RAND}   
   GROUP_NAME=PowerUserAccess-marketing-group-${RAND}
fi

#Call the create_group script to create the PowerUserAccess-marketing-group and attach all corresponding policies
./create_group.sh

source env.sh

#Create the user marketing-dave and its keys (which are added to keys.json), and add it to PowerUserAccess-marketing-group
aws iam create-user --user-name $USER_NAME
aws iam add-user-to-group --user-name $USER_NAME --group-name $GROUP_NAME
aws iam create-access-key --user-name $USER_NAME > keys.json


#Create the discovered-role-with-iam-privs role, and tag it
aws iam create-role --role-name $DISCOVERED_ROLE_NAME --assume-role-policy-document file://lambda_assume_policy_doc.json 
aws iam tag-role --role-name $DISCOVERED_ROLE_NAME --tags "${PROJECT_TAG}" || echo "Tagging not supported"


#Create the update_iam_policy (with the lambda_permissions_policy_doc.json as its document), 
#and attach it to the discovered-role-with-iam-privs role

aws iam create-policy --policy-name $POLICY_NAME --policy-document file://lambda_permissions_policy_doc.json > ${POLICY_NAME}_output.json
policy_arn=`cat ${POLICY_NAME}_output.json | jq '.Policy.Arn' | sed 's/\"//g' ` 
aws iam attach-role-policy --role-name $DISCOVERED_ROLE_NAME --policy-arn $policy_arn

#Set the POLICY_ARN value, to use it in other scripts
set_var POLICY_ARN $policy_arn

#List the policies to check if everything ran correctly
aws iam list-attached-role-policies --role-name $DISCOVERED_ROLE_NAME

#Create a zipfile to use in the creation of the lambda function
zip kingme.zip env.sh kingme.py

exit 0
