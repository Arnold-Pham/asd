#!/bin/bash

# Global
apt update && apt upgrade -y

# Docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    apt-get remove -y $pkg
done
apt-get install -y ca-certificates curl zip gnupg software-properties-common unzip
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
chmod 777 /var/run/docker.sock
usermod -aG docker $USER

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update
apt-get install terraform -y

# Ansible
apt install -y ansible

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm awscliv2.zip

# Hostname
CURRENT_HOSTNAME=$(hostname)
if [ "$CURRENT_HOSTNAME" != "sun" ]; then
    hostnamectl set-hostname sun
    sed -i "s/$CURRENT_HOSTNAME/sun/g" /etc/hosts
fi

SSH_DIR="/home/ubuntu/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
KEY_FILE="$SSH_DIR/key-cloud"
KEY_FILE_PUB="$KEY_FILE.pub"

ssh-keygen -t rsa -b 4096 -m PEM -C "key-cloud-$i" -f "$KEY_FILE" -N ""
chmod 600 "$KEY_FILE"
chmod 644 "$KEY_FILE_PUB"

# Terraform
TF_DIR="/home/ubuntu/Cloud/Terraform"
if [ -d "$TF_DIR" ]; then
    terraform -chdir="$TF_DIR" init
    terraform -chdir="$TF_DIR" apply -auto-approve
fi

chown -R ubuntu:ubuntu /home/ubuntu/.ssh

sleep 15

# Ansible
AN_DIR="/home/ubuntu/Cloud/Ansible"
if ! ansible-playbook -i "$AN_DIR/hosts" --private-key "$KEY_FILE" "$AN_DIR/install.yml" --ssh-common-args="-o StrictHostKeyChecking=accept-new"; then
    echo -e "${RED}❌ Le playbook Ansible a échoué.${RESET}"
    exit 1
fi