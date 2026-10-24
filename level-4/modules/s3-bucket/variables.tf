variable "bucket_name" {
  description = "Nombre del bucket S3"
  type        = string
}

variable "force_destroy" {
  description = "Permite eliminar el bucket aunque contenga objetos"
  type        = bool
  default     = false
}
