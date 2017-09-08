SSHLocation					:="120.148.10.232/32"
AWS_SERVER_SSH_KEY	:=rea_access_key
CF_TEMPLATE					:=./cloudformation/EC2instance.json
STACK_NAME					:=myteststack


build_infra:
	aws cloudformation create-stack --stack-name ${STACK_NAME} --template-body file://./${CF_TEMPLATE} --parameters ParameterKey=KeyName,ParameterValue=${AWS_SERVER_SSH_KEY} ParameterKey=SSHLocation,ParameterValue=${SSHLocation}
	echo "Waiting... this may take a while"
	aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}
	echo "${STACK_NAME} Created!"

update_infra:
	aws cloudformation update-stack --stack-name ${STACK_NAME} --template-body file://./${CF_TEMPLATE} --parameters ParameterKey=KeyName,ParameterValue=${AWS_SERVER_SSH_KEY} ParameterKey=SSHLocation,ParameterValue=${SSHLocation}
	echo "Waiting... this may take a while"
	aws cloudformation wait stack-update-complete --stack-name ${STACK_NAME}
	echo "${STACK_NAME} Updated!"

delete_infra:
	aws cloudformation delete-stack --stack-name ${STACK_NAME}
	echo "Waiting... this may take a while"
	aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME}
	echo "${STACK_NAME} Deleted!"

configure_aws:
	aws conigure

awscli_centos_install:
	./awscli/installawscli.bash
