#!/bin/bash
# Add the SSH public key from Terraform to the ubuntu user's authorized_keys
# This ensures Ansible can connect using the same key as the bastion host
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
echo "${public_key}" >> /home/ubuntu/.ssh/authorized_keys # This is line 6 in the template
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu
chmod 0440 /etc/sudoers.d/ubuntu