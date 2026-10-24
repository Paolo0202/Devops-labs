output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR de la VPC"
  value       = aws_vpc.this.cidr_block
}
