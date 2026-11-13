resource "random_password" "db_password" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "db" {
  name = "devops-capstone-db-credentials"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = "capstone_admin"
    password = random_password.db_password.result
    host     = aws_rds_cluster.main.endpoint
    port     = "5432"
    dbname   = "capstone"
  })
}
