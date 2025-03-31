#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

set -e

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  💥 Destruction de l'instance Terraform  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

BASE_DIR=$(pwd)
TF_FOLDER="$BASE_DIR/Sun/Terraform"

if [ -f "$BASE_DIR/Cloud/Terraform/terraform.tfvars" ]; then
    rm "$BASE_DIR/Cloud/Terraform/terraform.tfvars"
    echo -e "${CYAN}[INFO] 🗑️ Fichier terraform.tfvars supprimé.${RESET}"
else
    echo -e "${CYAN}[INFO] 🚫 Fichier terraform.tfvars non trouvé, ignorer la suppression.${RESET}"
fi

echo -e "${CYAN}[INFO] 🚧 Destruction de l'instance Terraform en cours...${RESET}"
terraform -chdir="$TF_FOLDER" destroy -auto-approve
echo -e "${GREEN}[OK] ✅ Instance Terraform détruite avec succès.${RESET}\n"

echo -e "${CYAN}[INFO] 🧹 Nettoyage des fichiers Terraform et clés SSH...\n${RESET}"

for file in "$TF_FOLDER/.terraform" "$TF_FOLDER/.terraform.lock.hcl" "$TF_FOLDER/sun-key" "$TF_FOLDER/sun-key.pub" "$TF_FOLDER/terraform.tfstate" "$TF_FOLDER/terraform.tfstate.backup"; do
    if [ -e "$file" ]; then
        rm -rf "$file"
        echo -e "${CYAN}[INFO] 🗑️ $file supprimé.${RESET}"
    else
        echo -e "${CYAN}[INFO] 🚫 $file non trouvé, ignorer la suppression.${RESET}"
    fi
done

for file in ./Sun/Ansible/hosts ./Sun/Ansible/script.log; do
    if [ -e "$file" ]; then
        rm -f "$file"
        echo -e "${CYAN}[INFO] 🗑️ $file supprimé.${RESET}"
    else
        echo -e "${CYAN}[INFO] 🚫 $file non trouvé, ignorer la suppression.${RESET}"
    fi
done

echo -e "/n${GREEN}[OK] 🧑‍💻 Nettoyage terminé avec succès !${RESET}\n"