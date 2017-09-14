#IP location locked down to local VPN network by default to access host exernally you need change these.
SSHLocation=172.31.0.0/16
HTTPLocation=172.31.0.0/16
AWS_SERVER_SSH_KEY=rea_access_key
AWS_SERVER_SSH_KEY_FILE=~/${AWS_SERVER_SSH_KEY}.pem
CF_TEST_TEMPLATE=cloudformation/EC2instance.json
CF_TEMPLATE=cloudformation/ELBWithLockedDownAutoScaledInstances.json
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
	@RETURN=$?
	@echo "Waiting... this may take a while"
	@aws cloudformation wait stack-create-complete --stack-name ${TEST_STACK_NAME}
	@sleep 10  # just a wait a little while incase the boot straping hasn't finished.
	@echo "${TEST_STACK_NAME} Created!"
	@echo "Your Test URL is :"
	@aws cloudformation describe-stacks --stack-name ${TEST_STACK_NAME} | jq '.Stacks[] .Outputs[3] .OutputValue' -r
	@exit ${RETURN}

delete_test_infra:
	@echo Deleting ${TEST_STACK_NAME} infrastructure...
	aws cloudformation delete-stack --stack-name ${TEST_STACK_NAME}
	@RETURN=$?
	@echo "Waiting... this may take a while"
	@aws cloudformation wait stack-delete-complete --stack-name ${TEST_STACK_NAME}
	@echo "${TEST_STACK_NAME} Deleted!"
	@exit ${RETURN}

validate_test_cf:
	@echo Validating cloudformation json : ${TEST_STACK_NAME}
	aws cloudformation validate-template --template-body file://./${CF_TEST_TEMPLATE}

build_infra:
	@echo Building ${STACK_NAME} infrastructure...
	aws cloudformation create-stack --stack-name ${STACK_NAME} --template-body file://./${CF_TEMPLATE} --parameters ParameterKey=KeyName,ParameterValue=${AWS_SERVER_SSH_KEY} ParameterKey=SSHLocation,ParameterValue=${SSHLocation} ParameterKey=Subnets,ParameterValue=\"${Subnets_2a},${Subnets_2b}\" ParameterKey=VpcId,ParameterValue=${VpcId} --disable-rollback
	@RETURN=$?
	@echo "Waiting... this may take a while"
	@aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}
	@echo "${STACK_NAME} Created!"
	@echo "Your URL is :"
	@aws cloudformation describe-stacks --stack-name ${STACK_NAME} | jq '.Stacks[] .Outputs[0] .OutputValue' -r
	@exit ${RETURN}

delete_infra:
	@echo Deleting ${STACK_NAME} infrastructure...
	aws cloudformation delete-stack --stack-name ${STACK_NAME}
	@RETURN=$?
	@echo "Waiting... this may take a while"
	@aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME}
	@echo "${STACK_NAME} Deleted!"
	@exit ${RETURN}

validate_cf:
	@echo Validating cloudformation json : ${STACK_NAME}
	aws cloudformation validate-template --template-body file://./${CF_TEMPLATE}

deploy_test_config:
	@echo "Deploying infra code to ${TEST_STACK_NAME}"
	@aws cloudformation describe-stacks --stack-name ${TEST_STACK_NAME} | jq '.Stacks[] .Outputs[3] .OutputValue' -r > ./ansible/hosts
	@tar czf - ./ansible | ssh -o "StrictHostKeyChecking no" -i ${AWS_SERVER_SSH_KEY_FILE} ${ansible_user}@`cat ./ansible/hosts` "tar xvzf -"
	ssh -o "StrictHostKeyChecking no" -tt -i ${AWS_SERVER_SSH_KEY_FILE} ${ansible_user}@`cat ./ansible/hosts` "cd ansible && sudo ansible-playbook -i "localhost," -c local  sinatra.yml"
	@RETURN=$?
	@echo "Infra code deployed to ${TEST_STACK_NAME}"
	@exit ${RETURN}

deploy_config_local:
	@echo "Deploying infra code local..."
	export ANSIBLE_HOST_KEY_CHECKING=FALSE && cd ./ansible && ansible-playbook -i "localhost," -C local sinatra.yml

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
	@echo
	@echo "build_test_infra:      Using cloud formation build test infrastructure stack ${TEST_STACK_NAME}"
	@echo "delete_test_infra:     Delete the test stack ${TEST_STACK_NAME}"
	@echo "validate_test_cf:      Validate the test stack cloudformation json"
	@echo "build_infra:           Using cloud formation build production infrastructure stack ${STACK_NAME}"
	@echo "delete_infra:          Delete the production stack ${STACK_NAME}"
	@echo "validate_cf:           Validate the production stack cloudformation json"
	@echo "deploy_test_config:    Deploy the test ansible code to the test stack ${TEST_STACK_NAME}"
	@echo "deploy_config_local:   Run the ansible code on the local host"
	@echo "cp_s3:	               Upload Anisble tarball to S3"
	@echo "help:                  Print this menu to the screen"
	@echo
