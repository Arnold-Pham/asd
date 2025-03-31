#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🚀 Mise à jour du système et installation des outils ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

echo -e "${CYAN}🔄 Mise à jour des paquets...${RESET}"
sudo apt update && sudo apt upgrade -y

echo -e "\n${CYAN}🗑️ Suppression des anciennes versions de Docker...${RESET}"
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y $pkg
done

echo -e "\n${CYAN}🔧 Installation des pré-requis pour Docker...${RESET}"
sudo apt-get install -y ca-certificates curl zip gnupg software-properties-common unzip

echo -e "\n${CYAN}🔑 Ajout de la clé GPG Docker...${RESET}"
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo -e "\n${CYAN}📦 Ajout du dépôt Docker...${RESET}"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

echo -e "\n${CYAN}🐳 Installation de Docker...${RESET}"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo -e "\n${CYAN}🔑 Configuration des permissions Docker...${RESET}"
sudo chmod 777 /var/run/docker.sock
sudo usermod -aG docker $USER

echo -e "\n${CYAN}🏗️ Installation de Terraform...${RESET}"
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform -y

echo -e "\n${CYAN}☁️ Installation d'AWS CLI...${RESET}"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm awscliv2.zip

CURRENT_HOSTNAME=$(hostname)
if [ "$CURRENT_HOSTNAME" != "Sun" ]; then
    echo -e "$\n{CYAN}🔄 Changement du nom de la machine en 'Sun'...${RESET}"
    sudo hostnamectl set-hostname Sun
    sudo sed -i "s/$CURRENT_HOSTNAME/Sun/g" /etc/hosts
    echo -e "\n${GREEN}✅ Nom de la machine modifié en 'Sun'${RESET}"
else
    echo -e "\n${GREEN}✅ Le nom de la machine est déjà 'Sun'.${RESET}"
fi

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🔑 Génération des clés SSH ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

SSH_DIR="/home/ubuntu/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
KEY_FILE="$SSH_DIR/cloud-key"
KEY_FILE_PUB="$SSH_DIR/cloud-key.pub"

if [ ! -f "$KEY_FILE" ]; then
    echo -e "${YELLOW}🛠️ Génération d'une nouvelle clé SSH...${RESET}"
    ssh-keygen -t rsa -b 4096 -m PEM -C "cloud-key" -f "$KEY_FILE" -N ""
    chmod 600 "$KEY_FILE"
    echo -e "\n${GREEN}✅ Clé SSH générée : $KEY_FILE${RESET}"
else
    echo -e "${GREEN}✅ La clé SSH existe déjà : $KEY_FILE${RESET}"
fi

chmod 600 "$KEY_FILE"
chmod 644 "$KEY_FILE_PUB"

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🌍 Déploiement avec Terraform ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

TF_DIR="/home/ubuntu/Cloud/Terraform"
if [ -d "$TF_DIR" ]; then
    echo -e "${CYAN}🛠️ Initialisation de Terraform...${RESET}"
    terraform -chdir="$TF_DIR" init
    
    echo -e "\n${CYAN}🚀 Application du plan Terraform...${RESET}"
    terraform -chdir="$TF_DIR" apply -auto-approve
else
    echo -e "${RED}❌ Le dossier Terraform est introuvable : $TF_DIR${RESET}"
fi

echo -e "\n${GREEN}🎉 Installation et déploiement terminés avec succès !${RESET}"