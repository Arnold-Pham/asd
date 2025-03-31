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

rm "$BASE_DIR/Cloud/Terraform/terraform.tfvars"

echo -e "\n${CYAN}[INFO] 🚧 Destruction de l'instance Terraform en cours...${RESET}"
terraform -chdir="$TF_FOLDER" destroy -auto-approve
echo -e "\n${GREEN}[OK] ✅ Instance Terraform détruite avec succès.${RESET}\n"

echo -e "${CYAN}[INFO] 🧹 Nettoyage des fichiers Terraform et clés SSH...${RESET}"
rm -rf "$TF_FOLDER/.terraform/"
rm "$TF_FOLDER/.terraform.lock.hcl"
rm "$TF_FOLDER/sun-key"
rm "$TF_FOLDER/sun-key.pub"
rm "$TF_FOLDER/terraform.tfstate"
rm "$TF_FOLDER/terraform.tfstate.backup"

rm -f ./Sun/Ansible/hosts
rm -f ./Sun/Ansible/script.log

echo -e "\n${GREEN}[OK] 🧑‍💻 Nettoyage terminé avec succès !${RESET}\n"