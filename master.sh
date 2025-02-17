#!/bin/bash

sudo apt update && sudo apt upgrade -y
sudo apt install -y curl unzip

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sleep 5

# Install K3s
curl -sfL https://get.k3s.io | sh -s - \
  --write-kubeconfig-mode 644 \
  --tls-san "$(curl ifconfig.me)" \
  --disable servicelb \
  --disable traefik

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Wait for Kubernetes API to be available
c=0
max=60

until [[ "$(curl -k -s -o /dev/null -w '%{http_code}' https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):6443/healthz)" == "401" ]]; do
  echo "Waiting for Kubernetes API to be available..."
  ((c++))
  if [[ ${c} -ge ${max} ]]; then
    exit 0
  fi
  sleep 5
done

sleep 120

# Ensure AWS CLI can authenticate
aws sts get-caller-identity >> /tmp/aws_sts.log 2>&1

# Export AWS region
export AWS_DEFAULT_REGION="eu-north-1"

# Debug logs for AWS SSM
aws ssm put-parameter --name "k3s_token" \
  --value "$(sudo cat /var/lib/rancher/k3s/server/node-token)" \
  --type "String" --overwrite \
  --region eu-north-1 >> /tmp/aws_ssm.log 2>&1

# Debugging: Check if token is stored
cat /tmp/aws_ssm.log

# Add Kubernetes alias
echo -e "
source <(kubectl completion bash)
alias k=kubectl