variable "aws_access_key" {
  description = "Access Key pour AWS"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "Secret Key pour AWS"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "instance_type" {
  description = "Type d'instance pour la machine Sun"
  type        = string
  default     = "t2.micro"
}

variable "vpc_cidr" {
  description = "Plage CIDR pour le VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "subnet_name" {
  description = "Liste des plages CIDR pour les sous-réseaux"
  type        = string
  default     = "Principale"
}

variable "subnet_cidr" {
  description = "Liste des plages CIDR pour les sous-réseaux"
  type        = string
  default     = "192.168.0.0/26"
}

variable "subnet_zone" {
  description = "Zone de disponibilité du sous-réseau 1"
  type        = string
  default     = "eu-west-3a"
}

variable "ssh_key_name" {
  description = "Nom de la clé SSH pour l'accès à la machine Sun"
  type        = string
  default     = "key-sun"
}

variable "ami" {
  description = "ID de l'AMI à utiliser pour l'instance Sun"
  type        = string
  default     = "ami-0160e8d70ebc43ee1"
}

variable "iam_policies" {
  description = "Liste des ARN des politiques IAM à attacher au rôle Sun"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]
}

variable "common_tags" {
  description = "Tags communs à appliquer à toutes les ressources"
  type        = map(string)
  default = {
    Project   = "Sun"
    ManagedBy = "Terraform"
  }
}

resource "random_id" "suffix" {
  byte_length = 8
}