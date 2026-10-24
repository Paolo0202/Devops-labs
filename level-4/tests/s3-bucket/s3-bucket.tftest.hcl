provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3 = "http://localhost:4566"
  }

  s3_use_path_style = true
}

run "valid_bucket_name" {
  command = plan

  variables {
    bucket_name = "test-tf-bootcamp-12345"
  }

  assert {
    condition     = output.bucket_name == "test-tf-bootcamp-12345"
    error_message = "El nombre del bucket no coincide con la variable"
  }

  assert {
    condition     = can(regex("^test-", output.bucket_name))
    error_message = "El nombre del bucket debe comenzar con test-"
  }
}
