#!/bin/bash

# install aws CLI in current users home dir.. ~/.local
# to run make sure you have sudo access, but don't run as root.
# jq is required to parse aws json

sudo yum install epel-release -y
sudo yum install python python-pip jq -y

pip install awscli --upgrade --user

echo "export PATH=~/.local/bin:$PATH" >> ~/.bash_profile

source ~/.bash_profile

echo "now run \"aws configure\" to setup you creds"
