output "sun_instance_id" {
  description = "ID de l'instance Sun"
  value       = aws_instance.sun.id
  sensitive   = true
}

output "sun_public_ip" {
  description = "Adresse IP publique de l'instance Sun"
  value       = aws_instance.sun.public_ip
}

output "subnet_id" {
  description = "ID du premier sous-réseau créé"
  value       = aws_subnet.subnet.id
  sensitive   = true
}

output "vpc_id" {
  description = "ID du VPC créé"
  value       = aws_vpc.main.id
  sensitive   = true
}

output "internet_gateway_id" {
  description = "ID de la passerelle Internet"
  value       = aws_internet_gateway.gw.id
  sensitive   = true
}

output "route_table_id" {
  description = "ID de la table de routage associée au sous-réseau 1"
  value       = aws_route_table.route_table.id
  sensitive   = true
}

output "security_group_id" {
  description = "ID du groupe de sécurité Sun"
  value       = aws_security_group.sun_sg.id
  sensitive   = true
}

output "sun_iam_role_id" {
  description = "ID du rôle IAM associé à l'instance Sun"
  value       = aws_iam_role.sun_role.id
  sensitive   = true
}

output "sun_iam_role_name" {
  description = "Nom du rôle IAM associé à l'instance Sun"
  value       = aws_iam_role.sun_role.name
}