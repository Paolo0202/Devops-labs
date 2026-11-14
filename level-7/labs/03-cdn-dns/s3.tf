resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "static" {
  bucket = "devops-capstone-static-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "devops-capstone-static"
  }
}

# Bloqueo de acceso público
resource "aws_s3_bucket_public_access_block" "static" {
  bucket = aws_s3_bucket.static.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Archivo HTML de ejemplo
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.static.id
  key          = "index.html"
  content      = "<html><body><h1>DevOps Capstone</h1><p>Static assets via CloudFront</p></body></html>"
  content_type = "text/html"
}
