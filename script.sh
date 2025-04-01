#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

BASE_DIR=$(pwd)
SUN_PUBLIC_IP=""

TF_FOLDER="$BASE_DIR/Sun/Terraform"
KEY_PATH="$TF_FOLDER/sun-key"
KEY_PATH_PUB="$TF_FOLDER/sun-key.pub"
LOCAL_VARS="$TF_FOLDER/terraform.tfvars.local"

ANSIBLE_FOLDER="$BASE_DIR/Sun/Ansible"
HOSTS_FILE="$ANSIBLE_FOLDER/hosts"

SSH_FOLDER="$HOME/.ssh"
NEW_KEY_PATH="$SSH_FOLDER/sun-key"
NEW_KEY_PATH_PUB="$SSH_FOLDER/sun-key.pub"

set -e

echo -e "${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🚀 Initialisation du déploiement  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

echo -e "${BOLD}${CYAN}🔍 Vérification de Terraform...${RESET}"
if ! command -v terraform &> /dev/null; then
    echo -e "\n${YELLOW}⚠️  Terraform non trouvé. Installation en cours...${RESET}\n"
    wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install -y terraform
    echo -e "\n${GREEN}✅ Terraform installé avec succès.${RESET}\n"
else
    echo -e "\n${GREEN}✅ Terraform est déjà installé.${RESET}\n"
fi

echo -e "${BOLD}${CYAN}🔍 Vérification de Ansible...${RESET}"
if ! command -v ansible &> /dev/null; then
    echo -e "\n${YELLOW}⚠️  Ansible non trouvé. Installation en cours...${RESET}\n"
    sudo apt update && sudo apt install -y ansible
    echo -e "\n${GREEN}✅ Ansible installé avec succès.${RESET}\n"
else
    echo -e "\n${GREEN}✅ Ansible est déjà installé.${RESET}\n"
fi

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🔑 Configuration des clés SSH  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

if [ ! -f "$KEY_PATH" ]; then
    echo -e "${YELLOW}🔨 Génération d'une nouvelle clé SSH...${RESET}\n"
    ssh-keygen -t rsa -b 4096 -m PEM -C "sun-key" -f "$KEY_PATH" -N ""
    echo -e "\n${GREEN}✅ Clé SSH générée avec succès.${RESET}\n"
else
    echo -e "${GREEN}🔑 Clé SSH existante : $KEY_PATH${RESET}\n"
fi

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🌍 Déploiement de l'instance AWS  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

echo -e "${CYAN}🔄 Initialisation de Terraform...${RESET}\n"
terraform -chdir="$TF_FOLDER" init

echo -e "\n${CYAN}🚀 Application du plan Terraform...${RESET}\n"
if [ -f "$LOCAL_VARS" ]; then
    terraform -chdir="$TF_FOLDER" apply -auto-approve -var-file="$LOCAL_VARS"
else
    terraform -chdir="$TF_FOLDER" apply -auto-approve
fi
echo -e "\n${GREEN}✅ Déploiement Terraform terminé.${RESET}\n"

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🌐 Récupération de l'IP publique  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n\n"

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
    echo -e "\n${GREEN}✅ Fichier d'inventaire Ansible mis à jour.${RESET}\n"
else
    echo -e "\n${RED}❌ Impossible de récupérer l'IP publique après plusieurs tentatives.${RESET}"
    exit 1
fi

VPC_ID=$(terraform -chdir="$TF_FOLDER" output -raw vpc_id)
if [ -f "$LOCAL_VARS" ]; then
    cp "$LOCAL_VARS" "$BASE_DIR/Cloud/Terraform/terraform.tfvars"
else
    cp "$TF_FOLDER/terraform.tfvars" "$BASE_DIR/Cloud/Terraform/terraform.tfvars"
fi
echo -e "\nvpc_id         = \"$VPC_ID\"" >> $BASE_DIR/Cloud/Terraform/terraform.tfvars

echo -e "\n\n${BLUE}=============================================${RESET}"
echo -e "${BLUE}  🔑 Déplacement des clés pour Ansible  ${RESET}"
echo -e "${BLUE}=============================================${RESET}\n"

rm -f "$NEW_KEY_PATH" "$NEW_KEY_PATH_PUB"
mkdir -p "$SSH_FOLDER"

cp "$KEY_PATH" "$SSH_FOLDER/"
cp "$KEY_PATH_PUB" "$SSH_FOLDER/"

chmod 700 "$SSH_FOLDER"
chmod 600 "$NEW_KEY_PATH"
chmod 644 "$NEW_KEY_PATH_PUB"

echo -e "${GREEN}[OK] Déplacement effectué.${RESET}\n"

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🚀 Lancement du playbook Ansible  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

sleep 15

echo -e "${CYAN}📦 Exécution du playbook Ansible...${RESET}\n"
if ! ansible-playbook -i "$HOSTS_FILE" --private-key "$NEW_KEY_PATH" "$ANSIBLE_FOLDER/install.yml" --ssh-common-args="-o StrictHostKeyChecking=accept-new"; then
    echo -e "${RED}❌ Le playbook Ansible a échoué.${RESET}"
    exit 1
fi

echo -e "${GREEN}🎉 Déploiement terminé avec succès !${RESET}\n"