#!/bin/bash

# Update system and install required tools
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl unzip

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sleep 5

# Get Master Private IP (from Terraform or Metadata)
#MASTER_PRIVATE_IPV4="<MASTER_PRIVATE_IP>"
REGION="eu-north-1"  # Update the region if needed

# Wait for Kubernetes API to be available
c=0
max=60

while true; do
  STATUS_CODE=$(curl -k -s -o /dev/null -w '%{http_code}' https://$MASTER_PRIVATE_IPV4:6443/healthz)
  
  if [[ "$STATUS_CODE" == "401" ]]; then
    echo "Kubernetes API is ready!"
    break
  fi

  echo "Waiting for Kubernetes API... (Attempt: $c)"
  ((c++))

  if [[ $c -ge $max ]]; then
    echo "Error: Kubernetes API did not become available."
    exit 1
  fi

  sleep 5
done

# Wait for K3s Token to be available in AWS SSM Parameter Store
count=0
retries=30

while true; do
  K3S_TOKEN_SSM=$(aws ssm get-parameters --names k3s_token --query 'Parameters[0].Value' --output text --region $REGION)
  
  if [[ "$K3S_TOKEN_SSM" != "empty" && -n "$K3S_TOKEN_SSM" ]]; then
    echo "✅Successfully retrieved K3S token."
    break
  fi

  ((count++))
  if [[ $count -ge $retries ]]; then
    echo " Could not retrieve K3S token."
    exit 1
  fi

  sleep 10
done

# Install K3s Node and Join to the Cluster
curl -sfL https://get.k3s.io | K3S_URL="https://$MASTER_PRIVATE_IPV4:6443" K3S_TOKEN="$K3S_TOKEN_SSM" sh -

echo " K3s Node Setup Complete!"
