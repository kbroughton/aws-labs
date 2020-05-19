# aws-labs
A collection of security focused labs for AWS.
Labs 1-3 are deep dives into AWS IAM.

## Quickstart
For lab 1, you may prefer to run natively on your laptop.
Other labs make use of the Dockerfile included.

```
git clone https://github.com/kbroughton/aws-labs.git
cd aws-labs
docker build -t aws-labs:latest
docker-compose up -d
```

Follow the Readme for each lab.
If there are any issues, we recommend running from the docker container provided.
This is intermediate level and assumes some familiarity with AWS. 
In Lab 1, we start with basic cli and bash.
Lab 2 we move to a jupyter notebook for the exercises.
