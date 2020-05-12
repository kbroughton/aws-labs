#!/bin/bash

set -x

usage='Creates the group for marketing power users with Lambda, SQS and NotAction policies.'

if [ x$1 != x ]; then
    if [ $1 == "help" ] || [ $1 == "--help" ]; then
      echo "${usage}"
      exit 0
    fi
fi

source env.sh

#Set the variables needed
GROUP_NAME=PowerUserAccess-marketing-group-$RAND
POLICY_NAME=PowerUserAccess-marketing-Deny-IAM-$RAND
POLICY_ARN=arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${POLICY_NAME}

#Delete option used by the delete.sh script
if [ $1 == "--delete" ]; then
   aws iam detach-group-policy --group-name $GROUP_NAME --policy-arn arn:aws:iam::aws:policy/AmazonSQSFullAccess
   aws iam detach-group-policy --group-name $GROUP_NAME --policy-arn arn:aws:iam::aws:policy/AWSLambdaFullAccess
   aws iam delete-group-policy --policy-name $POLICY_NAME --group-name $GROUP_NAME
   aws iam remove-user-from-group --user-name $USER_NAME --group-name $GROUP_NAME
   aws iam delete-group --group-name $GROUP_NAME
   exit 0
fi

#Create the group and attach/put the corresponding policies
aws iam create-group --group-name $GROUP_NAME
aws iam put-group-policy --group-name $GROUP_NAME --policy-name $POLICY_NAME --policy-document file://power_user_marketing_not_action_policy_doc.json
aws iam attach-group-policy --group-name $GROUP_NAME --policy-arn arn:aws:iam::aws:policy/AmazonSQSFullAccess
aws iam attach-group-policy --group-name $GROUP_NAME --policy-arn arn:aws:iam::aws:policy/AWSLambdaFullAccess




