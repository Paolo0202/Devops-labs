terraform {
  backend "s3" {
    bucket       = "devops-capstone-tfstate-181259113150-2026"
    key          = "capstone/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
