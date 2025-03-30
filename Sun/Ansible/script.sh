#!/bin/bash

# Définition des couleurs pour un affichage plus lisible
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

echo -e "\n${BLUE}=============================================${RESET}"
echo -e "${BLUE}  Mise à jour du système et installation des outils ${RESET}"
echo -e "${BLUE}=============================================${RESET}\n"

# Mettre à jour et upgrader le système
echo -e "${CYAN}[INFO] Mise à jour des paquets...${RESET}"
sudo apt update && sudo apt upgrade -y

# Suppression des anciennes versions de Docker et de certains autres paquets
echo -e "${CYAN}[INFO] Suppression des paquets Docker existants...${RESET}"
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y $pkg
done

# Installation des pré-requis pour Docker
echo -e "${CYAN}[INFO] Installation des pré-requis pour Docker...${RESET}"
sudo apt-get install -y ca-certificates curl zip gnupg software-properties-common unzip

# Ajouter la clé GPG de Docker
echo -e "${CYAN}[INFO] Ajout de la clé GPG officielle de Docker...${RESET}"
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Ajouter le dépôt Docker aux sources APT
echo -e "${CYAN}[INFO] Ajout du dépôt Docker...${RESET}"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Installer Docker et ses composants
echo -e "${CYAN}[INFO] Installation de Docker...${RESET}"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Mettre à jour les permissions pour le socket Docker
echo -e "${CYAN}[INFO] Mise à jour des permissions du socket Docker...${RESET}"
sudo chmod 777 /var/run/docker.sock

# Ajouter l'utilisateur actuel au groupe Docker
echo -e "${CYAN}[INFO] Ajout de l'utilisateur au groupe Docker...${RESET}"
sudo usermod -aG docker $USER

# Installer Terraform
echo -e "${CYAN}[INFO] Installation de Terraform...${RESET}"
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform -y

# Installer AWS CLI
echo -e "${CYAN}[INFO] Installation d'AWS CLI...${RESET}"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm awscliv2.zip

# Vérifier et changer le nom de la machine si nécessaire
CURRENT_HOSTNAME=$(hostname)
if [ "$CURRENT_HOSTNAME" != "Sun" ]; then
    echo -e "${CYAN}[INFO] Changement du nom de la machine en 'Sun'...${RESET}"
    sudo hostnamectl set-hostname Sun

    # Mettre à jour le fichier /etc/hosts pour correspondre au nouveau nom
    sudo sed -i "s/$CURRENT_HOSTNAME/Sun/g" /etc/hosts
    echo -e "${GREEN}[OK] Nom de la machine modifié en 'Sun'${RESET}"
else
    echo -e "${GREEN}[OK] Le nom de la machine est déjà 'Sun'.${RESET}"
fi

# Création des clés SSH pour chaque instance Cloud-n
echo -e "\n${BLUE}=============================================${RESET}"
echo -e "${BLUE}  Génération des clés SSH pour les machines Cloud ${RESET}"
echo -e "${BLUE}=============================================${RESET}\n"

SSH_DIR="/home/ubuntu/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

KEY_FILE="$SSH_DIR/cloud-key"
if [ ! -f "$KEY_FILE" ]; then
    echo -e "${YELLOW}[INFO] Génération d'une nouvelle clé SSH pour Ubuntu Server AWS...${RESET}"
    ssh-keygen -t rsa -b 4096 -m PEM -C "cloud-key" -f "$KEY_PATH" -N ""
    echo -e "${GREEN}[OK] Clé SSH générée : $KEY_PATH${RESET}"
    chmod 600 "$KEY_FILE"
else
    echo -e "${GREEN}[OK] La clé SSH existe déjà : $KEY_PATH${RESET}"
fi

# # Vérifier la présence de Terraform et exécuter l'init/apply
# echo -e "\n${BLUE}=============================================${RESET}"
# echo -e "${BLUE}  Déploiement de l'infrastructure avec Terraform ${RESET}"
# echo -e "${BLUE}=============================================${RESET}\n"

# TF_DIR="/home/ubuntu/Cloud/Terraform"
# if [ -d "$TF_DIR" ]; then
#     echo -e "${CYAN}[INFO] Initialisation de Terraform...${RESET}"
#     terraform -chdir="$TF_DIR" init

#     echo -e "${CYAN}[INFO] Application du plan Terraform...${RESET}"
#     terraform -chdir="$TF_DIR" apply -auto-approve
# else
#     echo -e "${RED}[ERROR] Le dossier Terraform est introuvable à l'emplacement : $TF_DIR${RESET}"
# fi

# echo -e "${GREEN}[OK] Installation et déploiement terminés avec succès !${RESET}\n"
