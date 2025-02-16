#!/bin/bash

sudo apt update
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

curl -sfL https://get.k3s.io | sh -s - \
  --write-kubeconfig-mode 644 \
  --tls-san "$(curl ifconfig.me)" \
  --disable servicelb \
  --disable traefik

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

c=0
max=60

until [[ "$(curl -k -s -o /dev/null -w '%{http_code}' https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):6443/healthz)" == "401" ]];  do
  echo "Waiting for Kubernetes API to be available..."
  ((c++))
  if [[ ${c} -ge ${max} ]]; then
    exit 0
  fi
  sleep 5
done

