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

echo -e "\n${CYAN}☁️ Installation d'AWS CLI...${RESET}"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm awscliv2.zip

NEW_HOSTNAME="$1"
CURRENT_HOSTNAME=$(hostname)
if [ "$CURRENT_HOSTNAME" != "$NEW_HOSTNAME" ]; then
    echo -e "$\n{CYAN}🔄 Changement du nom de la machine en '$NEW_HOSTNAME'...${RESET}"
    sudo hostnamectl set-hostname "$NEW_HOSTNAME"
    sudo sed -i "s/$CURRENT_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts
    echo -e "\n${GREEN}✅ Nom de la machine modifié en '$NEW_HOSTNAME'${RESET}"
else
    echo -e "\n${GREEN}✅ Le nom de la machine est déjà '$NEW_HOSTNAME'.${RESET}"
fi