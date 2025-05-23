#!/bin/bash

# Update system and install required tools
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl unzip

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sleep 10

# for test purposes
echo "master_private_ip = ${master_private_ip}" > /var/tmp/master_private_ip
echo "region = ${region}" > /var/tmp/region


# Get Master Private IP (from Terraform or Metadata)
#export master_private_ip="${master_private_ip}"
#export region="eu-north-1"  # Update the region if needed

# Wait for Kubernetes API to be available
sleep 380

export K3S_TOKEN_SSM="$(aws ssm get-parameters --names k3s_token --query 'Parameters[0].Value' --output text --region ${region})"
curl -sfL https://get.k3s.io | K3S_URL=https://${master_private_ip}:6443 K3S_TOKEN=$K3S_TOKEN_SSM sh -