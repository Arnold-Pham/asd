#!/bin/bash

# Définition des couleurs
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

echo -e "\n${BLUE}=============================================${RESET}"
echo -e "${BLUE}  Vérification et installation des outils  ${RESET}"
echo -e "${BLUE}=============================================${RESET}\n"

# Vérifier si Terraform est installé
if ! command -v terraform &> /dev/null; then
    echo -e "${YELLOW}[INFO] Terraform n'est pas installé. Installation en cours...${RESET}"
    wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install -y terraform
    echo -e "${GREEN}[OK] Terraform installé avec succès.${RESET}"
else
    echo -e "${GREEN}[OK] Terraform est déjà installé.${RESET}"
fi

echo ""

# Vérifier si Ansible est installé
if ! command -v ansible &> /dev/null; then
    echo -e "${YELLOW}[INFO] Ansible n'est pas installé. Installation en cours...${RESET}"
    sudo apt update && sudo apt install -y ansible
    echo -e "${GREEN}[OK] Ansible installé avec succès.${RESET}"
else
    echo -e "${GREEN}[OK] Ansible est déjà installé.${RESET}"
fi

echo -e "\n${BLUE}=============================================${RESET}"
echo -e "${BLUE}  Configuration des chemins et clés SSH  ${RESET}"
echo -e "${BLUE}=============================================${RESET}\n"

# Définition des chemins absolus
BASE_DIR=$(pwd)
TF_FOLDER="$BASE_DIR/Sun/Terraform"
ANSIBLE_FOLDER="$BASE_DIR/Sun/Ansible"
KEY_PATH="$TF_FOLDER/sun-key"
HOSTS_FILE="$ANSIBLE_FOLDER/hosts"

# Vérifier si la clé SSH existe déjà
if [ -f "$KEY_PATH" ]; then
    echo -e "${GREEN}[OK] La clé SSH existe déjà : $KEY_PATH${RESET}"
else
    echo -e "${YELLOW}[INFO] Génération d'une nouvelle clé SSH pour Ubuntu Server AWS...${RESET}"
    ssh-keygen -t rsa -b 4096 -m PEM -C "sun-key" -f "$KEY_PATH" -N ""
    echo -e "${GREEN}[OK] Clé SSH générée : $KEY_PATH${RESET}"
fi

echo -e "\n${BLUE}=============================================${RESET}"
echo -e "${BLUE}  Déploiement de l'instance avec Terraform  ${RESET}"
echo -e "${BLUE}=============================================${RESET}\n"

# Déploiement de la machine avec Terraform
echo -e "${CYAN}[INFO] Initialisation de Terraform...${RESET}"
terraform -chdir="$TF_FOLDER" init

echo -e "${CYAN}[INFO] Application du plan Terraform...${RESET}"
terraform -chdir="$TF_FOLDER" apply -auto-approve
echo -e "${GREEN}[OK] Déploiement Terraform terminé.${RESET}"

echo -e "\n${BLUE}=============================================${RESET}"
echo -e "${BLUE}  Récupération de l'IP publique  ${RESET}"
echo -e "${BLUE}=============================================${RESET}\n"

# Récupération de l'IP publique et mise à jour de l'inventaire Ansible
SUN_PUBLIC_IP=$(terraform -chdir="$TF_FOLDER" output -raw sun_public_ip)
if [ -n "$SUN_PUBLIC_IP" ]; then
    echo -e "${CYAN}[INFO] IP récupérée : ${SUN_PUBLIC_IP}${RESET}"
    echo -e "[sun]\n$SUN_PUBLIC_IP" > "$HOSTS_FILE"
    echo -e "${GREEN}[OK] Fichier d'inventaire Ansible mis à jour.${RESET}"
else
    echo -e "${RED}[ERROR] Impossible de récupérer l'IP publique.${RESET}"
    exit 1
fi

echo -e "\n${BLUE}=============================================${RESET}"
echo -e "${BLUE}  Exécution du playbook Ansible  ${RESET}"
echo -e "${BLUE}=============================================${RESET}\n"

# Exécution du playbook Ansible
echo -e "${CYAN}[INFO] Démarrage du playbook Ansible...${RESET}"
ansible-playbook -i "$HOSTS_FILE" --private-key "$KEY_PATH" "$ANSIBLE_FOLDER/install.yml" --ssh-common-args="-o StrictHostKeyChecking=accept-new"

echo -e "${GREEN}[OK] Déploiement terminé avec succès !${RESET}\n"
