#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

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

echo -e "${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🚀 Lancement du playbook Ansible  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

echo -e "${CYAN}📦 Exécution du playbook Ansible...${RESET}\n"
if ! ansible-playbook -i "$HOSTS_FILE" --private-key "$SUN_KEY" "$AN_FOLDER/destroy.yml" --ssh-common-args="-o StrictHostKeyChecking=accept-new"; then
    echo -e "${RED}❌ Le playbook Ansible a échoué.${RESET}"
    exit 1
fi

echo -e "\n${GREEN}🎉 Destruction Cloud-n terminé avec succès !${RESET}\n"

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  💥 Destruction de l'instance Terraform  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

if [ -f "$CLOUD_VARS" ]; then
    rm "$CLOUD_VARS"
    echo -e "\n${CYAN}[INFO] 🗑️ Fichier $CLOUD_VARS supprimé.${RESET}"
else
    echo -e "\n${CYAN}[INFO] 🚫 Fichier $CLOUD_VARS non trouvé, ignorer la suppression.${RESET}"
fi

echo -e "\n${CYAN}[INFO] 🚧 Destruction de l'instance Terraform en cours...${RESET}\n"
if [ -f "$LOCAL_VARS" ]; then
    terraform -chdir="$TF_FOLDER" destroy -auto-approve -var-file="$LOCAL_VARS"
else
    terraform -chdir="$TF_FOLDER" destroy -auto-approve
fi
echo -e "\n${GREEN}[OK] ✅ Instance Terraform détruite avec succès.${RESET}"

echo -e "\n${CYAN}[INFO] 🧹 Nettoyage des fichiers Terraform et clés SSH...${RESET}\n"

for file in "$SUN_KEY" "$SUN_KEY_PUB" "$HOSTS_FILE" "$TF_FOLDER/.terraform" "$TF_FOLDER/.terraform.lock.hcl" "$TF_FOLDER/terraform.tfstate" "$TF_FOLDER/terraform.tfstate.backup"; do
    if [ -e "$file" ]; then
        rm -rf "$file"
        echo -e "${CYAN}[INFO] 🗑️ $file supprimé.${RESET}"
    else
        echo -e "${CYAN}[INFO] 🚫 $file non trouvé, ignorer la suppression.${RESET}"
    fi
done

echo -e "\n${GREEN}[OK] 🧑‍💻 Nettoyage terminé avec succès !${RESET}"