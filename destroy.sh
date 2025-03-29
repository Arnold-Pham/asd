#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

set -e
echo -e "\n${BLUE}=============================================${RESET}"
echo -e "${BLUE}  Destruction de l'instance Terraform  ${RESET}"
echo -e "${BLUE}=============================================${RESET}\n"

BASE_DIR=$(pwd)
TF_FOLDER="$BASE_DIR/Sun/Terraform"

if [ ! -d "$TF_FOLDER" ]; then
    echo -e "${RED}[ERROR] Le dossier Terraform n'existe pas à l'emplacement suivant : $TF_FOLDER${RESET}"
    exit 1
fi

echo -e "${CYAN}[INFO] Destruction de l'instance Terraform en cours...${RESET}"
terraform -chdir="$TF_FOLDER" destroy -auto-approve
echo -e "${GREEN}[OK] Instance Terraform détruite avec succès.${RESET}\n"