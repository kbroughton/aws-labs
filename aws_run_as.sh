#!/usr/bin/env bash
 set -x

usage="Usage: awsas  [--debug] [--profie aprofile] role-name <aws subcommand and options>. \nA dynamic version of --profile. Whereas --profile requires setting up configuration, awsas allows you to assume roles without setup. \nEg. awsas myrole sts get-caller-identity should return identity for myrole\n"


function unset_aws() {
    unset AWS_ACCESS_KEY_ID
    unset  AWS_SECRET_ACCESS_KEY
    unset  AWS_SESSION_TOKEN
}

function awsas () {
    if [ $# -eq 0 ]; then
      printf "${usage}"
      exit 0
    fi

    debug=""

    if [[ $1 == "--debug" ]]; then
      debug="DEBUG"
      shift
      echo "args: $@"
    fi

    unset_aws

    if [[ $1 == "--profile" ]]; then
      shift
      export profile=$1
      shift
      if [[ $debug == "DEBUG" ]]; then
        echo "Setting profile to $profile"
      fi
      account_id=`aws --profile $profile sts get-caller-identity | jq '.Account' | sed 's|\"||g'`
      role=$1
      shift
      role_arn=""
      if [[ $1 == "--path" ]]; then
          shift
          path=$1
          shift
          role_arn="arn:aws:iam::$account_id:role$path$role"
      else
          role_arn="arn:aws:iam::$account_id:role/$role"
      fi
      if [[ $debug == "DEBUG" ]]; then
        echo "assuming role arn $role_arn"
      fi
      creds=`aws --profile $profile sts assume-role --role-arn $role_arn --role-session-name $role`
      if [[ $debug == "DEBUG" ]]; then
          echo "`echo ${creds} | jq '.AssumedRoleUser.Arn'`"
      fi
    else
      echo $@
      role=$1
      shift
      echo "role: $role"
      role_arn=""
      account_id=`aws sts get-caller-identity | jq '.Account' | sed 's|\"||g'`
      if [[ $1 == "--path" ]]; then
          shift
          path=$1
          shift
          role_arn="arn:aws:iam::$account_id:role$path$role"
      else
          role_arn="arn:aws:iam::$account_id:role/$role"
      fi

      if [[ $debug == "DEBUG" ]]; then
         printf "Using account $account_id \n Calling aws sts assume-role --role-arn $role_arn --role-session-name $role \n"
         printf "Remaining args: $@ \n"
      fi
      creds=`aws sts assume-role --role-arn $role_arn --role-session-name $role`
    fi



    export AWS_ACCESS_KEY_ID=`echo ${creds} | jq '.Credentials.AccessKeyId' | sed 's|\"||g'`
    export AWS_SECRET_ACCESS_KEY=`echo ${creds} | jq '.Credentials.SecretAccessKey' | sed 's|\"||g'`
    export AWS_SESSION_TOKEN=`echo ${creds} | jq '.Credentials.SessionToken' | sed 's|\"||g'`
    aws "$@"

    unset_aws
}

awsas "$@"
