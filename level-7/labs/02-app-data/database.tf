
# Subnet group para RDS (usa las subnets privadas)
resource "aws_db_subnet_group" "main" {
  name       = "devops-capstone-db-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "devops-capstone-db-subnet"
  }
}

# Cluster Aurora Serverless v2
resource "aws_rds_cluster" "main" {
  cluster_identifier = "devops-capstone-db"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "16.4"
  database_name      = "capstone"

  master_username = "capstone_admin"
  master_password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = true

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2.0
  }

  tags = {
    Name = "devops-capstone-db"
  }
}

# Instancia Aurora Serverless v2
resource "aws_rds_cluster_instance" "main" {
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  tags = {
    Name = "devops-capstone-db-instance"
  }
}
