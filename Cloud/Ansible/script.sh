#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

echo -e "${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🚀 Mise à jour et installation des outils ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

echo -e "\n${CYAN}🔄 Mise à jour des paquets...${RESET}\n"
apt update && apt upgrade -y

echo -e "\n${CYAN}🗑️ Suppression des anciennes versions de Docker...${RESET}\n"
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    apt-get remove -y $pkg
done

echo -e "\n${CYAN}🔧 Installation des pré-requis pour Docker...${RESET}\n"
apt-get install -y ca-certificates curl zip gnupg software-properties-common unzip

echo -e "\n${CYAN}🔑 Ajout de la clé GPG Docker...${RESET}\n"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo -e "\n${CYAN}📦 Ajout du dépôt Docker...${RESET}\n"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update

echo -e "\n${CYAN}🐳 Installation de Docker...${RESET}\n"
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo -e "\n${CYAN}🔑 Configuration des permissions Docker...${RESET}\n"
chmod 777 /var/run/docker.sock
usermod -aG docker $USER

echo -e "\n${CYAN}☁️ Installation d'AWS CLI...${RESET}\n"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm awscliv2.zip