variable "environment" {
  description = "Entorno de despliegue"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El entorno debe ser dev, staging o prod."
  }
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "bootcamp"
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

variable "db_password" {
  description = "Contrasena de base de datos"
  type        = string
  sensitive   = true
}
