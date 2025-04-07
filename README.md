# Infrastructure ASD

## Shéma

![Shema d'infrastructure](./shema.png)

## Prérequis

- Un ordinateur sous linux ou utilisation de WSL
- Avoir des identifiants AWS

## Préparations préalables

- Modifier le fichier `./Sun/Terraform/terraform.tfvars` ou créer `./Sun/Terraform/terraform.tfvars.local` avec les informations suivantes:
    - aws_access_key = `<clé d'accès générée dans IAM>`
    - aws_secret_key = `<clé secrète générée dans IAM>`
- Modifier les variables de Terraform au besoin dans `./Sun/Terraform/variables.tf` et `./Cloud/Terraform/variables.tf` (entre autre)
- Lancer WSL
- Lancer la commande `sudo ./script.sh`