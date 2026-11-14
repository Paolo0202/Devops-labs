resource "aws_ecr_repository" "flask" {
  name                 = "devops-capstone-flask"
  force_delete         = true
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "devops-capstone-flask"
  }
}

resource "aws_cloudwatch_log_group" "flask" {
  name              = "/ecs/devops-capstone-flask"
  retention_in_days = 7

  tags = {
    Name = "devops-capstone-flask-logs"
  }
}
