SSHLocation="120.148.10.232/32"
HTTPLocation="120.148.10.232/32"
AWS_SERVER_SSH_KEY=rea_access_key
#CF_TEMPLATE=./cloudformation/EC2instance.json
#CF_TEMPLATE=./cloudformation/EC2instance_aws2.json
CF_TEMPLATE=./cloudformation/ELBWithLockedDownAutoScaledInstances.json
STACK_NAME=myteststack
Subnets_2a=subnet-615c4e17
Subnets_2b=subnet-821bf9e5
VpcId=vpc-41d78e25
ansible_user=centos
S3=https://s3-ap-southeast-2.amazonaws.com/fab-sinatra-anisble/ansible


all:	help


elb_test:
	aws cloudformation create-stack --stack-name ${STACK_NAME} --template-body file://./${CF_TEMPLATE} --parameters ParameterKey=KeyName,ParameterValue=${AWS_SERVER_SSH_KEY} ParameterKey=SSHLocation,ParameterValue=${SSHLocation} ParameterKey=HTTPLocation,ParameterValue=${HTTPLocation} ParameterKey=Subnets,ParameterValue=\"${Subnets_2a},${Subnets_2b}\" ParameterKey=VpcId,ParameterValue=${VpcId} --disable-rollback
	@echo "Waiting... this may take a while"
	@aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}
	@aws cloudformation describe-stacks --stack-name ${STACK_NAME}

elb_update:
	aws cloudformation update-stack --stack-name ${STACK_NAME} --template-body file://./${CF_TEMPLATE} --parameters ParameterKey=KeyName,ParameterValue=${AWS_SERVER_SSH_KEY} ParameterKey=SSHLocation,ParameterValue=${SSHLocation} ParameterKey=Subnets,ParameterValue='${Subnets_2a} ${Subnets_2b}' ParameterKey=VpcId,ParameterValue=${VpcId}
	@echo "Waiting... this may take a while"

build_infra:
	aws cloudformation create-stack --stack-name ${STACK_NAME} --template-body file://./${CF_TEMPLATE} --parameters ParameterKey=KeyName,ParameterValue=${AWS_SERVER_SSH_KEY} ParameterKey=SSHLocation,ParameterValue=${SSHLocation} ParameterKey=HTTPLocation,ParameterValue=${HTTPLocation} --disable-rollback
	@echo "Waiting... this may take a while"
	@aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}
	@echo "Your Test URL is :"
	@aws cloudformation describe-stacks --stack-name ${STACK_NAME} | jq '.Stacks[] .Outputs[3] .OutputValue' -r
	@echo "${STACK_NAME} Created!"

deploy_config:
	@echo "Deploying infra code..."
	#@aws cloudformation describe-stacks --stack-name ${STACK_NAME} | jq '.Stacks[] .Outputs[1] .OutputValue' -r > ./ansible/hosts
	@tar czf - ./ansible | ssh -o "StrictHostKeyChecking no" -i ~/${AWS_SERVER_SSH_KEY}.pem ${ansible_user}@`cat ./ansible/hosts` "tar xvzf -"
	ssh -o "StrictHostKeyChecking no" -tt -i ~/${AWS_SERVER_SSH_KEY}.pem ${ansible_user}@`cat ./ansible/hosts` "cd ansible && sudo ansible-playbook -i "localhost," -c local  sinatra.yml"
	@#export ANSIBLE_HOST_KEY_CHECKING=FALSE && cd ./ansible && ansible-playbook -u ${ansible_user} --private-key ~/rea_access_key.pem --sudo -i ./hosts --module-path=./library sinatra.yml

deploy_config_local:
	@echo "Deploying infra code local..."
	export ANSIBLE_HOST_KEY_CHECKING=FALSE && cd ./ansible && ansible-playbook -i "localhost," -C local --module-path=./library sinatra.yml

cp_s3:
	@echo copying ansible code to s3 bucket ${S3}
	tar -cvf ./ansible.tar ./ansible
	aws s3 cp ./ansible.tar s3://fab-sinatra-anisble/ansible/ansible.tar

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

validate_cf:
	#aws cloudformation validate-template --template-body file://./${CF_TEMPLATE} --parameters ParameterKey=KeyName,ParameterValue=${AWS_SERVER_SSH_KEY} ParameterKey=SSHLocation,ParameterValue=${SSHLocation} ParameterKey=HTTPLocation,ParameterValue=${HTTPLocation}
	aws cloudformation validate-template --template-body file://./${CF_TEMPLATE}

help:
	@echo build_infra
	@echo deploy_config
	@echo update_infra
	@echo delete_infra
	@echo configure_awscli
	@echo aws_centos_install
	@echo help
