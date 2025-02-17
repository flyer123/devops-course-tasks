#!/bin/bash

sudo apt update && sudo apt upgrade -y
sudo apt install -y curl unzip

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sleep 5

PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Install K3s using Private IP
curl -sfL https://get.k3s.io | sh -s - \
  --write-kubeconfig-mode 644 \
  --tls-san "$PRIVATE_IP" \
  --disable servicelb \
  --disable traefik

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml


# Wait for Kubernetes API to be available
c=0
max=60

until [[ "$(curl -k -s -o /dev/null -w '%{http_code}' https://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):6443/healthz)" == "401" ]];  do
  echo "Waiting for Kubernetes API to be available..."
  ((c++))
  if [[ ${c} -ge ${max} ]]; then
    exit 0
  fi
  sleep 5
done

aws ssm put-parameter --name "k3s_token" \
  --value "$(sudo cat /var/lib/rancher/k3s/server/node-token)" \
  --type "String" --overwrite \
  --region eu-north-1

echo -e "
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k" >> /home/ubuntu/.bashrc >> ~/.bashrc