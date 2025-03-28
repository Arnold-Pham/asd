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
  # default     = "t3.large"
  default     = "t2.micro"
}

variable "vpc_cidr" {
  description = "Plage CIDR pour le VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "subnet_cidrs" {
  description = "Liste des plages CIDR pour les sous-réseaux"
  type        = list(string)
  default     = ["192.168.0.0/24", "192.168.1.0/24"]
}

variable "subnet_zone1" {
  description = "Zone de disponibilité du sous-réseau 1"
  type        = string
  default     = "eu-west-3a"
}

variable "subnet_zone2" {
  description = "Zone de disponibilité du sous-réseau 2"
  type        = string
  default     = "eu-west-3b"
}

variable "ssh_key_name" {
  description = "Nom de la clé SSH pour l'accès à la machine Sun"
  type        = string
  default     = "sun-key"
}