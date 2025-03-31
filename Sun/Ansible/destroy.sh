#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

set -e

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  💥 Destruction des instances Terraform  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

BASE_DIR=$(pwd)
TF_FOLDER="$BASE_DIR/Cloud/Terraform"

echo -e "${CYAN}[INFO] 🚧 Destruction des instances Terraform en cours...${RESET}"
terraform -chdir="$TF_FOLDER" destroy -auto-approve -lock=false
echo -e "${GREEN}[OK] ✅ Instances Terraform détruites avec succès.${RESET}\n"