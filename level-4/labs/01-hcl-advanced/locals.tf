locals {
  prefix      = "${var.environment}-${var.project_name}"
  bucket_name = "${local.prefix}-data"

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })

  subnet_public = cidrsubnet("10.0.0.0/16", 8, 0)
}
