SSHLocation="120.148.10.232/32"
HTTPLocation="120.148.10.232/32"
AWS_SERVER_SSH_KEY=rea_access_key
CF_TEST_TEMPLATE=./cloudformation/EC2instance.json
CF_TEMPLATE=./cloudformation/ELBWithLockedDownAutoScaledInstances.json
STACK_NAME=prodsinatrastack
TEST_STACK_NAME=testsinatrastack
Subnets_2a=subnet-615c4e17
Subnets_2b=subnet-821bf9e5
VpcId=vpc-41d78e25
ansible_user=centos
S3_bucket=s3://simple-sinatra


all:	help


build_test_infra:
	@echo Building ${TEST_STACK_NAME} infrastructure...
	aws cloudformation create-stack --stack-name ${TEST_STACK_NAME} --template-body file://./${CF_TEST_TEMPLATE} --parameters ParameterKey=KeyName,ParameterValue=${AWS_SERVER_SSH_KEY} ParameterKey=SSHLocation,ParameterValue=${SSHLocation} ParameterKey=HTTPLocation,ParameterValue=${HTTPLocation} --disable-rollback
	@echo "Waiting... this may take a while"
	@aws cloudformation wait stack-create-complete --stack-name ${TEST_STACK_NAME}
	@echo "${TEST_STACK_NAME} Created!"
	@echo "Your Test URL is :"
	@aws cloudformation describe-stacks --stack-name ${TEST_STACK_NAME} | jq '.Stacks[] .Outputs[3] .OutputValue' -r

delete_test_infra:
	@echo Deleting ${TEST_STACK_NAME} infrastructure...
	aws cloudformation delete-stack --stack-name ${TEST_STACK_NAME}
	@echo "Waiting... this may take a while"
	@aws cloudformation wait stack-delete-complete --stack-name ${TEST_STACK_NAME}
	@echo "${TEST_STACK_NAME} Deleted!"

validate_test_cf:
	@echo Validating cloudformation json : ${TEST_STACK_NAME}
	aws cloudformation validate-template --template-body file://./${CF_TEST_TEMPLATE}

build_infra:
	@echo Building ${STACK_NAME} infrastructure...
	aws cloudformation create-stack --stack-name ${STACK_NAME} --template-body file://./${CF_TEMPLATE} --parameters ParameterKey=KeyName,ParameterValue=${AWS_SERVER_SSH_KEY} ParameterKey=SSHLocation,ParameterValue=${SSHLocation} ParameterKey=HTTPLocation,ParameterValue=${HTTPLocation} ParameterKey=Subnets,ParameterValue=\"${Subnets_2a},${Subnets_2b}\" ParameterKey=VpcId,ParameterValue=${VpcId} --disable-rollback
	@echo "Waiting... this may take a while"
	@aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}
	@echo "${STACK_NAME} Created!"
	@echo "Your Test URL is :"
	@aws cloudformation describe-stacks --stack-name ${STACK_NAME} | jq '.Stacks[] .Outputs[0] .OutputValue' -r

delete_infra:
	@echo Deleting ${STACK_NAME} infrastructure...
	aws cloudformation delete-stack --stack-name ${STACK_NAME}
	@echo "Waiting... this may take a while"
	@aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME}
	@echo "${STACK_NAME} Deleted!"

validate_cf:
	@echo Validating cloudformation json : ${STACK_NAME}
	aws cloudformation validate-template --template-body file://./${CF_TEMPLATE}

deploy_test_config:
	@echo "Deploying infra code to ${TEST_STACK_NAME}"
	@aws cloudformation describe-stacks --stack-name ${TEST_STACK_NAME} | jq '.Stacks[] .Outputs[3] .OutputValue' -r > ./ansible/hosts
	@tar czf - ./ansible | ssh -o "StrictHostKeyChecking no" -i ~/${AWS_SERVER_SSH_KEY}.pem ${ansible_user}@`cat ./ansible/hosts` "tar xvzf -"
	ssh -o "StrictHostKeyChecking no" -tt -i ~/${AWS_SERVER_SSH_KEY}.pem ${ansible_user}@`cat ./ansible/hosts` "cd ansible && sudo ansible-playbook -i "localhost," -c local  sinatra.yml"
	@echo "Infra code deployed to ${TEST_STACK_NAME}"

deploy_config_local:
	@echo "Deploying infra code local..."
	export ANSIBLE_HOST_KEY_CHECKING=FALSE && cd ./ansible && ansible-playbook -i "localhost," -C local --module-path=./library sinatra.yml

cp_s3:
	@echo "Uploading Ansible tar to S3 bucket ${S3_bucket}"
	@echo copying ansible code to s3 bucket ${S3}
	@tar -cvf ./ansible.tar ./ansible
	aws s3 cp ./ansible.tar ${S3_bucket}/ansible.tar


configure_awscli:
	aws conigure

awscli_centos_install:
	./awscli/installawscli.bash

help:
	@echo build_test_infra
	@echo delete_test_infra
	@echo validate_test_cf
	@echo build_infra
	@echo delete_infra
	@echo validate_cf
	@echo deploy_test_config
	@echo deploy_config_local
	@echo help
