SSHLocation="120.148.10.232/32"
HTTPLocation="120.148.10.232/32"
AWS_SERVER_SSH_KEY=rea_access_key
CF_TEMPLATE=./cloudformation/EC2instance.json
STACK_NAME=myteststack




all:	help

build_infra:
	aws cloudformation create-stack --stack-name ${STACK_NAME} --template-body file://./${CF_TEMPLATE} --parameters ParameterKey=KeyName,ParameterValue=${AWS_SERVER_SSH_KEY} ParameterKey=SSHLocation,ParameterValue=${SSHLocation} ParameterKey=HTTPLocation,ParameterValue=${HTTPLocation}
	@echo "Waiting... this may take a while"
	@aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}
	@echo "Your Test URL is :"
	@aws cloudformation describe-stacks --stack-name myteststack | jq '.Stacks[] .Outputs[3] .OutputValue' -r
	@echo "${STACK_NAME} Created!"
	@cat ./ansible/hosts

deploy_config:
	@echo "Deploying infra code..."
	@aws cloudformation describe-stacks --stack-name myteststack | jq '.Stacks[] .Outputs[1] .OutputValue' -r > ./ansible/hosts
	export ANSIBLE_HOST_KEY_CHECKING=FALSE && cd ./ansible && ansible-playbook -u centos --private-key ~/rea_access_key.pem --sudo -i ./hosts  sinatra.yml

update_infra:
	aws cloudformation update-stack --stack-name ${STACK_NAME} --template-body file://./${CF_TEMPLATE} --parameters ParameterKey=KeyName,ParameterValue=${AWS_SERVER_SSH_KEY} ParameterKey=SSHLocation,ParameterValue=${SSHLocation} ParameterKey=HTTPLocation,ParameterValue=${HTTPLocation}
	@echo "Waiting... this may take a while"
	@aws cloudformation wait stack-update-complete --stack-name ${STACK_NAME}
	@echo "Your Test URL is :"
	@aws cloudformation describe-stacks --stack-name myteststack | jq '.Stacks[] .Outputs[3] .OutputValue' -r 
	@cat ./ansible/hosts
	@echo "${STACK_NAME} Updated!"

delete_infra:
	aws cloudformation delete-stack --stack-name ${STACK_NAME}
	@echo "Waiting... this may take a while"
	@aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME}
	@echo "${STACK_NAME} Deleted!"

configure_awscli:
	aws conigure

awscli_centos_install:
	./awscli/installawscli.bash

get_hosts:
	aws cloudformation describe-stacks --stack-name myteststack | jq '.Stacks[] .Outputs[1] .OutputValue' -r > ./ansible/hosts

help:
	@echo build_infra
	@echo deploy_config
	@echo update_infra
	@echo delete_infra
	@echo configure_awscli
	@echo aws_centos_install
	@echo help
