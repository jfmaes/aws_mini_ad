#!/bin/bash

# Variables
KEY_PATH="$(pwd)/ssh_key"
CURRENT_WORKDIR=$(pwd)
#TERRAFORM_STATE_FILE="$(pwd)/terraform/terraform.tfstate"

# Key Creation
if [ -f "$KEY_PATH" ]; then
    echo "Key file found! Removing the key file"
    rm ssh_key ssh_key.pub 2> /dev/null
fi


rm student.ovpn 2> /dev/null
rm windows-key-pair.pem 2> /dev/null
echo "Generating new ssh key $KEY_PATH"
ssh-keygen -b 2048 -t rsa -f "$KEY_PATH" -q -N ""
chmod 0600 ssh_key


# Scenario Dev Spin Up
cd ..
cd terraform
terraform init
terraform apply -auto-approve

