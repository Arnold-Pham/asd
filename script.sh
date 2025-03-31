#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

set -e

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🚀 Initialisation du déploiement  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

echo -e "${BOLD}${CYAN}🔍 Vérification de Terraform...${RESET}"
if ! command -v terraform &> /dev/null; then
    echo -e "${YELLOW}⚠️  Terraform non trouvé. Installation en cours...${RESET}"
    wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install -y terraform
    echo -e "${GREEN}✅ Terraform installé avec succès.${RESET}"
else
    echo -e "${GREEN}✅ Terraform est déjà installé.${RESET}"
fi

echo -e "\n${BOLD}${CYAN}🔍 Vérification de Ansible...${RESET}"
if ! command -v ansible &> /dev/null; then
    echo -e "${YELLOW}⚠️  Ansible non trouvé. Installation en cours...${RESET}"
    sudo apt update && sudo apt install -y ansible
    echo -e "${GREEN}✅ Ansible installé avec succès.${RESET}"
else
    echo -e "${GREEN}✅ Ansible est déjà installé.${RESET}"
fi

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🔑 Configuration des clés SSH  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

BASE_DIR=$(pwd)
TF_FOLDER="$BASE_DIR/Sun/Terraform"
ANSIBLE_FOLDER="$BASE_DIR/Sun/Ansible"
KEY_PATH="$TF_FOLDER/sun-key"
SSH_FOLDER="$HOME/.ssh"
NEW_KEY_PATH="$SSH_FOLDER/sun-key"
HOSTS_FILE="$ANSIBLE_FOLDER/hosts"

if [ ! -f "$KEY_PATH" ]; then
    echo -e "${YELLOW}🔨 Génération d'une nouvelle clé SSH...${RESET}"
    ssh-keygen -t rsa -b 4096 -m PEM -C "sun-key" -f "$KEY_PATH" -N ""
    echo -e "${GREEN}✅ Clé SSH générée avec succès.${RESET}"
else
    echo -e "${GREEN}🔑 Clé SSH existante : $KEY_PATH${RESET}"
fi

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🌍 Déploiement de l'instance AWS  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

echo -e "${CYAN}🔄 Initialisation de Terraform...${RESET}"
terraform -chdir="$TF_FOLDER" init

echo -e "\n${CYAN}🚀 Application du plan Terraform...${RESET}"
terraform -chdir="$TF_FOLDER" apply -auto-approve
echo -e "\n${GREEN}✅ Déploiement Terraform terminé.${RESET}"

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🌐 Récupération de l'IP publique  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

SUN_PUBLIC_IP=""
for i in {1..5}; do
    SUN_PUBLIC_IP=$(terraform -chdir="$TF_FOLDER" output -raw sun_public_ip)
    if [ -n "$SUN_PUBLIC_IP" ]; then
        echo -e "${CYAN}🌍 IP récupérée : ${SUN_PUBLIC_IP}${RESET}"
        break
    else
        echo -e "${YELLOW}🔄 Tentative $i/5 pour récupérer l'IP publique...${RESET}"
        sleep 10
    fi
done

if [ -n "$SUN_PUBLIC_IP" ]; then
    echo -e "[sun]\n$SUN_PUBLIC_IP" > "$HOSTS_FILE"
    echo -e "${GREEN}✅ Fichier d'inventaire Ansible mis à jour.${RESET}"
else
    echo -e "${RED}❌ Impossible de récupérer l'IP publique après plusieurs tentatives.${RESET}"
    exit 1
fi

sleep 15

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🚀 Lancement du playbook Ansible  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

echo -e "${CYAN}📦 Exécution du playbook Ansible...${RESET}\n"
if ! ansible-playbook -i "$HOSTS_FILE" --private-key "$NEW_KEY_PATH" "$ANSIBLE_FOLDER/install.yml" --ssh-common-args="-o StrictHostKeyChecking=accept-new"; then
    echo -e "${RED}❌ Le playbook Ansible a échoué.${RESET}"
    exit 1
fi

echo -e "${GREEN}🎉 Déploiement terminé avec succès !${RESET}\n"
sleep 5
ssh -i "$KEY_PATH" ubuntu@$SUN_PUBLIC_IPs