#!/bin/bash

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

set -e

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

sudo apt update > /dev/null 2>&1 && sudo apt upgrade -y > /dev/null 2>&1
sleep 1

echo -e "${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🚀  Initialisation du déploiement  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

echo -e "${BOLD}${CYAN}[INFO] 🔍 Vérification de Terraform...${RESET}"
if ! command -v terraform &> /dev/null; then
    echo -e "${YELLOW}[WARN] ⚠️\tTerraform non trouvé. Installation en cours...${RESET}"
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt-get install terraform -y
    echo -e "${GREEN}[OK] ✅  Terraform installé avec succès${RESET}"
    sleep 2
else
    echo -e "${GREEN}[OK] ✅  Terraform est déjà installé${RESET}"
fi

echo -e "${BOLD}${CYAN}[INFO] 🔍 Vérification de Ansible...${RESET}"
if ! command -v ansible &> /dev/null; then
    echo -e "${YELLOW}[WARN] ⚠️\tAnsible non trouvé. Installation en cours...${RESET}"
    sudo apt update && sudo apt install -y ansible
    echo -e "${GREEN}[OK] ✅  Ansible installé avec succès${RESET}"
    sleep 2
else
    echo -e "${GREEN}[OK] ✅  Ansible est déjà installé${RESET}"
fi

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🔑 Configuration des clés SSH  ${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

mkdir -p "$SSH_FOLDER"
chmod 700 "$SSH_FOLDER"

if [ ! -f "$KEY_SUN" ]; then
    echo -e "${CYAN}[INFO] 🔨\tGénération d'une nouvelle clé SSH...${RESET}"
    ssh-keygen -t rsa -b 4096 -m PEM -C "key-sun" -f "$KEY_SUN" -N ""
    echo -e "${GREEN}[OK] ✅  Clé SSH générée avec succès${RESET}"
    sleep 2
else
    echo -e "${GREEN}🔑 Clé SSH existante : $KEY_SUN${RESET}"
fi

chmod 600 "$KEY_SUN"
chmod 644 "$KEY_SUN_PUB"
chown -R $USER:$USER "$SSH_FOLDER"

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🌍 Déploiement de l'instance AWS${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}\n"

echo -e "${CYAN}[INFO] 🔄\tInitialisation de Terraform...${RESET}"
terraform -chdir="$TF_FOLDER" init

echo -e "\n${CYAN}[INFO] 🚀\tApplication du plan Terraform...${RESET}"
if [ -f "$LOCAL_VARS" ]; then
    terraform -chdir="$TF_FOLDER" apply -auto-approve -var-file="$LOCAL_VARS"
    sleep 1
    cp "$LOCAL_VARS" "$CLOUD_VARS"
else
    terraform -chdir="$TF_FOLDER" apply -auto-approve
    sleep 1
    cp "$NORMAL_VARS" "$CLOUD_VARS"
fi

echo -e "${GREEN}[OK] ✅  Déploiement Terraform terminé${RESET}"

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🌐 Récupération de l'IP publique${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}"
sleep 3

for i in {1..5}; do
    SUN_PUBLIC_IP=$(terraform -chdir="$TF_FOLDER" output -raw sun_public_ip) 
    if [ -n "$SUN_PUBLIC_IP" ]; then
        echo -e "${CYAN}[INFO] 🌍\tIP récupérée : ${SUN_PUBLIC_IP}${RESET}"
        break
    else
        echo -e "${YELLOW}[WARN] 🔄\tTentative $i/5 pour récupérer l'IP publique...${RESET}"
        sleep 3
    fi
done

if [ -n "$SUN_PUBLIC_IP" ]; then
    echo -e "[sun]\n$SUN_PUBLIC_IP" > "$HOSTS_FILE"
    echo -e "${GREEN}[OK] ✅  Fichier d'inventaire Ansible mis à jour${RESET}"
else
    echo -e "${BOLD}${RED}╷\n│  Error: ${RESET}IP publique non récupérée\n${BOLD}${RED}╵${RESET}"
    exit
fi

echo -e "\nvpc_id         = \"$(terraform -chdir="$TF_FOLDER" output -raw vpc_id)\"" >> "$CLOUD_VARS"

echo -e "\n${BOLD}${BLUE}=============================================${RESET}"
echo -e "${BOLD}${BLUE}  🚀 Lancement du playbook Ansible${RESET}"
echo -e "${BOLD}${BLUE}=============================================${RESET}"
sleep 3

echo -e "\n${CYAN}[INFO] 📦\tExécution du playbook Ansible...${RESET}"
if ! sudo ansible-playbook -i "$HOSTS_FILE" --private-key "$KEY_SUN" "$AN_FOLDER/install.yml" --ssh-common-args="-o StrictHostKeyChecking=accept-new"; then
    echo -e "${BOLD}${RED}╷\n│  Error: ${RESET}Echec du playbook Ansible\n${BOLD}${RED}╵${RESET}"
    exit
fi
sleep 1

echo -e "#!/bin/bash\n\nsudo ssh -i \"$KEY_SUN\" ubuntu@$SUN_PUBLIC_IP" > ./connexion.sh
echo -e "${GREEN}[OK] ✅  Déploiement terminé avec succès !${RESET}\n"