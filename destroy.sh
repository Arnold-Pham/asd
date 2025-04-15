#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

BASE=$(pwd)
SUN_PUBLIC_IP=""
TF_FOLDER="$BASE/Sun/Terraform"
NORMAL_VARS="$TF_FOLDER/terraform.tfvars"
LOCAL_VARS="$TF_FOLDER/terraform.tfvars.local"
AN_FOLDER="$BASE/Sun/Ansible"
HOSTS_FILE="$AN_FOLDER/hosts"
SSH_FOLDER="$HOME/.ssh"
KEY_SUN="$SSH_FOLDER/key-sun"
KEY_SUN_PUB="$SSH_FOLDER/key-sun.pub"
CLOUD_VARS="$BASE/Cloud/Terraform/terraform.tfvars"

echo -e "${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🚀  Destructions des instances distantes${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

echo -e "${CYAN}[INFO] 📦\tExécution du playbook Ansible...${RESET}"
if ! sudo ansible-playbook -i "$HOSTS_FILE" --private-key "$KEY_SUN" "$AN_FOLDER/destroy.yml" --ssh-common-args="-o StrictHostKeyChecking=accept-new"; then
    echo -e "${BOLD}${RED}╷\n│  Error: ${RESET}Echec du playbook Ansible\n${BOLD}${RED}╵${RESET}"
else
    echo -e "${GREEN}[OK] ✅  Destruction Cloud-n terminé avec succès !${RESET}"
fi

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  💥  Destruction de l'instance Terraform${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

echo -e "${CYAN}[INFO] 💥\tDestruction de l'instance Terraform en cours...${RESET}"
if [ -f "$LOCAL_VARS" ]; then
    terraform -chdir="$TF_FOLDER" destroy -auto-approve -var-file="$LOCAL_VARS"
else
    terraform -chdir="$TF_FOLDER" destroy -auto-approve
fi
echo -e "${GREEN}[OK] ✅  Instance Terraform détruite avec succès.${RESET}"

echo -e "\n${BOLD}${BLUE}=======================================================${RESET}"
echo -e "${BOLD}${BLUE}🧹  Nettoyage des fichiers Terraform et clés SSH...${RESET}"
echo -e "${BOLD}${BLUE}=======================================================${RESET}\n"

for file in "$KEY_SUN" "$KEY_SUN_PUB" "$HOSTS_FILE" "$TF_FOLDER/.terraform" "$TF_FOLDER/.terraform.lock.hcl" "$TF_FOLDER/terraform.tfstate" "$TF_FOLDER/terraform.tfstate.backup" "$CLOUD_VARS" "$BASE/connexion.sh"; do
    if [ -e "$file" ]; then
        sudo rm -rf "$file"
        echo -e "${CYAN}[INFO] 🗑️\t$file supprimé.${RESET}"
        sleep 1
    else
        echo -e "${CYAN}[INFO] 🚫   $file non trouvé, ignorer la suppression.${RESET}"
    fi
done

echo -e "${GREEN}[OK] ✅  Nettoyage terminé avec succès !${RESET}"