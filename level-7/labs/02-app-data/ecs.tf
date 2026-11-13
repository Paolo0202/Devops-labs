
resource "aws_ecs_cluster" "main" {
  name = "devops-capstone-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "devops-capstone-cluster"
  }
}


resource "aws_ecs_task_definition" "flask" {
  family                   = "devops-capstone-flask"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "flask"
    image = "${aws_ecr_repository.flask.repository_url}:latest"
    portMappings = [{
      containerPort = 5001
      protocol      = "tcp"
    }]
    environment = [
  { name = "S3_ENDPOINT", value = "" },
  { name = "S3_BUCKET", value = "bootcamp-capstone-7d6f8470" }
]
    secrets = [
      { name = "DB_HOST", valueFrom = "${aws_secretsmanager_secret.db.arn}:host::" },
      { name = "DB_PASSWORD", valueFrom = "${aws_secretsmanager_secret.db.arn}:password::" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.flask.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "flask"
      }
    }
  }])
}


resource "aws_ecr_repository" "flask" {
  name                 = "devops-capstone-flask"
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


resource "aws_ecs_service" "flask" {
  name            = "devops-capstone-flask"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.flask.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.flask.arn
    container_name   = "flask"
    container_port   = 5001
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "devops-capstone-flask"
  }
}
