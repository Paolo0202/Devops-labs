output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "s3_bucket_name" {
  description = "Static assets S3 bucket"
  value       = aws_s3_bucket.static.id
}
