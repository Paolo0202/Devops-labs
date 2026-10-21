output "prefix" {
  description = "Prefijo generado"
  value       = local.prefix
}

output "bucket_name" {
  description = "Nombre del bucket de datos"
  value       = local.bucket_name
}

output "common_tags" {
  description = "Tags comunes fusionados"
  value       = local.common_tags
}

output "subnet_public" {
  description = "Primera subred publica calculada"
  value       = local.subnet_public
}

output "db_password" {
  description = "Contrasena de BD (sensitive)"
  value       = var.db_password
  sensitive   = true
}
