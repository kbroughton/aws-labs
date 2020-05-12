FROM jupyter/scipy-notebook

LABEL Project="https://github.com/kbroughton/aws-labs"

USER root
EXPOSE 8080
WORKDIR /aws-labs
ENV AWS_DEFAULT_REGION=us-east-1 

RUN apt-get update -y
RUN apt-get install -y build-essential autoconf automake libtool python3.7-dev python3-tk jq awscli nano zip
RUN apt-get install -y bash

COPY . /aws-labs

RUN cp /aws-labs/aws_run_as.sh /etc/profile.d
RUN cat aws_run_as.sh  > /usr/local/bin/awsas && chmod a+x /usr/local/bin/awsas
ENV HOME /root
RUN bash
