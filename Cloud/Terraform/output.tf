output "cloud_1_instance_id" {
  description = "ID de l'instance Cloud 1"
  value       = aws_instance.cloud_1.id
  sensitive   = true
}

output "cloud_2_instance_id" {
  description = "ID de l'instance Cloud 2"
  value       = aws_instance.cloud_2.id
  sensitive   = true
}

output "cloud_3_instance_id" {
  description = "ID de l'instance Cloud 3"
  value       = aws_instance.cloud_3.id
  sensitive   = true
}

output "cloud_4_instance_id" {
  description = "ID de l'instance Cloud 4"
  value       = aws_instance.cloud_4.id
  sensitive   = true
}

output "cloud_1_public_ip" {
  description = "Adresse IP publique de l'instance Cloud 1"
  value       = aws_instance.cloud_1.public_ip
}

output "cloud_2_public_ip" {
  description = "Adresse IP publique de l'instance Cloud 2"
  value       = aws_instance.cloud_2.public_ip
}

output "cloud_3_public_ip" {
  description = "Adresse IP publique de l'instance Cloud 3"
  value       = aws_instance.cloud_3.public_ip
}

output "cloud_4_public_ip" {
  description = "Adresse IP publique de l'instance Cloud 4"
  value       = aws_instance.cloud_4.public_ip
}