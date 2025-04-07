#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e "\n${BOLD}${RED} ❌  SCRIPT A EXECUTER EN TANT QUE ROOT OU AVEC SUDO  ❌ ${RESET}\n"
    exit 1
fi

BASE=$(pwd)
SUN_PUBLIC_IP=""
TF_FOLDER="$BASE/Sun/Terraform"
NORMAL_VARS="$TF_FOLDER/terraform.tfvars"
LOCAL_VARS="$TF_FOLDER/terraform.tfvars.local"
AN_FOLDER="$BASE/Sun/Ansible"
HOSTS_FILE="$AN_FOLDER/hosts"
SSH_FOLDER="$HOME/.ssh"
SUN_KEY="$SSH_FOLDER/sun-key"
SUN_KEY_PUB="$SSH_FOLDER/sun-key.pub"
CLOUD_VARS="$BASE/Cloud/Terraform/terraform.tfvars"

apt update && apt upgrade -y

echo -e "${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🚀 Initialisation du déploiement  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

echo -e "${BOLD}${CYAN}🔍 Vérification de Terraform...${RESET}"
if ! command -v terraform &> /dev/null; then
    echo -e "\n${YELLOW}⚠️  Terraform non trouvé. Installation en cours...${RESET}\n"
    wget -O - https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
    apt update && apt install -y terraform
    echo -e "${GREEN}✅ Terraform installé avec succès.${RESET}\n"
    sleep 2
else
    echo -e "${GREEN}✅ Terraform est déjà installé.${RESET}\n"
fi


echo -e "${BOLD}${CYAN}🔍 Vérification de Ansible...${RESET}"
if ! command -v ansible &> /dev/null; then
    echo -e "\n${YELLOW}⚠️  Ansible non trouvé. Installation en cours...${RESET}\n"
    apt update && apt install -y ansible
    echo -e "${GREEN}✅ Ansible installé avec succès.${RESET}\n"
    sleep 2
else
    echo -e "${GREEN}✅ Ansible est déjà installé.${RESET}\n"
fi


echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🔑 Configuration des clés SSH  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

chmod 700 "$SSH_FOLDER"

if [ ! -f "$SUN_KEY" ]; then
    echo -e "${YELLOW}🔨 Génération d'une nouvelle clé SSH...${RESET}\n"
    ssh-keygen -t rsa -b 4096 -m PEM -C "sun-key" -f "$SUN_KEY" -N ""
    echo -e "${GREEN}✅ Clé SSH générée avec succès.${RESET}\n"
    sleep 2
else
    echo -e "${GREEN}🔑 Clé SSH existante : ${$SUN_KEY}${RESET}\n"
fi

chmod 600 "$SUN_KEY"
chmod 644 "$SUN_KEY_PUB"

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🌍 Déploiement de l'instance AWS  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

echo -e "${CYAN}🔄 Initialisation de Terraform...${RESET}\n"
terraform -chdir="$TF_FOLDER" init

echo -e "\n${CYAN}🚀 Application du plan Terraform...${RESET}\n"
if [ -f "$LOCAL_VARS" ]; then
    terraform -chdir="$TF_FOLDER" apply -auto-approve -var-file="$LOCAL_VARS"
    sleep 2
    cp "$LOCAL_VARS" "$CLOUD_VARS"
else
    terraform -chdir="$TF_FOLDER" apply -auto-approve
    sleep 2
    cp "$NORMAL_VARS" "$CLOUD_VARS"
fi
echo -e "${GREEN}✅ Déploiement Terraform terminé.${RESET}\n"

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
    echo -e "${GREEN}✅ Fichier d'inventaire Ansible mis à jour.${RESET}\n"
else
    echo -e "${RED}❌ Impossible de récupérer l'IP publique après plusieurs tentatives.${RESET}"
    exit 1
fi

echo -e "\nvpc_id         = \"$(terraform -chdir="$TF_FOLDER" output -raw vpc_id)\"" >> "$CLOUD_VARS"

# echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
# echo -e "${BOLD}${BLUE}  🚀 Lancement du playbook Ansible  ${RESET}"
# echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

# sleep 5

# echo -e "${CYAN}📦 Exécution du playbook Ansible...${RESET}"
# if ! ansible-playbook -i "$HOSTS_FILE" --private-key "$SUN_KEY" "$AN_FOLDER/install.yml" --ssh-common-args="-o StrictHostKeyChecking=accept-new"; then
#     echo -e "${RED}❌ Le playbook Ansible a échoué.${RESET}"
#     exit 1
# fi

# sleep 2

# echo -e "${GREEN}🎉 Déploiement terminé avec succès !${RESET}\n"