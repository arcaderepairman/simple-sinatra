Notes: some hardcode values here, just for my refernce later on.

How to run :

Deploy CF template:
aws cloudformation create-stack --stack-name myteststack --template-body file://./EC2instance --parameters ParameterKey=KeyName,ParameterValue=rea_access_key ParameterKey=SSHLocation,ParameterValue=120.148.10.232/32

Get status :
aws cloudformation describe-stacks --stack-name myteststack  | grep status

Delete stack :
aws cloudformation delete-stack --stack-name myteststack


Centos ami I am using : 
CentOS Linux 7 x86_64 HVM EBS 1704_01-b7ee8a69-ee97-4a49-9e68-afaee216db2e-ami-d52f5bc3.4 (ami-34171d57)
Description
CentOS Linux 7 x86_64 HVM EBS 1704_01
Status
available
Platform
Cent OS
Image Size
8GB
Visibility
Public
Owner
