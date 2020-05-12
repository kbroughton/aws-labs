import boto3
import os

#Gets the username from the env.sh file.
#This is needed because the username changes everytime the lab is run.

#Handler for the lambda function.
def handler(event, context):
  username=os.environ['USER_NAME']
  result = ""
  try:
    client = boto3.client("iam")
    result = client.attach_user_policy(
      UserName=username,
      PolicyArn='arn:aws:iam::aws:policy/AdministratorAccess'
    )
  except Exception as e:
    print(e)
  return {
    'statusCode': 200,
    'body': result
  }
