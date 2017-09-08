#!/bin/bash

# install aws CLI in current users home dir.. ~/.local
# to run make sure you have sudo access, but don't run as root.
#

sudo yum install python python-pip -y

pip install awscli --upgrade --user

echo "export PATH=~/.local/bin:$PATH" >> ~/.bash_profile

source ~/.bash_profile

echo "now run aws configure to setup you creds"
