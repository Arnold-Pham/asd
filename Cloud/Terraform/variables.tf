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
  description = "Type d'instance pour les machines Cloud"
  type        = string
  default     = "t2.micro"
}

variable "vpc_id" {
  description = "ID du VPC existant"
  type        = string
}

variable "subnet_cidr" {
  description = "Liste des plages CIDR pour les sous-réseaux"
  type        = string
  default     = "192.168.1.0/24"
}

variable "subnet_zone" {
  description = "Zone de disponibilité du sous-réseau 2"
  type        = string
  default     = "eu-west-3b"
}

variable "ssh_key_name" {
  description = "Nom de la clé SSH pour l'accès aux machines Cloud"
  type        = string
  default     = "cloud-key"
}

variable "ami" {
  description = "ID de l'AMI à utiliser pour les instances Cloud"
  type        = string
  default     = "ami-0160e8d70ebc43ee1"
}

variable "iam_policies" {
  description = "Liste des ARN des politiques IAM à attacher au rôle Cloud"
  type        = list(string)
  default     = [
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]
}

variable "common_tags" {
  description = "Tags communs à appliquer à toutes les ressources Cloud"
  type        = map(string)
  default     = {
    Project   = "Cloud"
    ManagedBy = "Terraform"
  }
}

variable "private_ips" {
  description = "Liste des IPs privées à assigner aux instances Cloud"
  type        = list(string)
  default     = ["192.168.1.11", "192.168.1.12", "192.168.1.13", "192.168.1.14"]
}

resource "random_id" "suffix" {
  byte_length = 8
}