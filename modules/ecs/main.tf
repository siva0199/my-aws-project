# Security group for the ALB (allows web traffic from anyone)
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for ECS Instances (allows traffic only from the ALB)
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-tasks-sg"
  description = "Allow traffic from ALB to ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 0 # All ports
    to_port         = 0
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The Application Load Balancer (ALB)
resource "aws_lb" "main" {
  name               = "project-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [var.public_subnet_id, var.public_subnet_b_id]
}

# Target Groups (one for each NGINX service)
resource "aws_lb_target_group" "nginx_a" {
  name_prefix  = "nga-" # Use a shorter prefix (6 chars or less)
  port         = 80
  protocol     = "HTTP"
  vpc_id       = var.vpc_id
  target_type  = "ip"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "nginx_b" {
  name_prefix  = "ngb-" # Use a shorter prefix (6 chars or less)
  port         = 80
  protocol     = "HTTP"
  vpc_id       = var.vpc_id
  target_type  = "ip"

  lifecycle {
    create_before_destroy = true
  }
}

# The ALB Listener (listens on port 80 and forwards traffic)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.nginx_a.arn
        weight = 50
      }
      target_group {
        arn    = aws_lb_target_group.nginx_b.arn
        weight = 50
      }
    }
  }
}

# The ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "project-cluster"
}

# EC2 Launch Template (tells our instances how to start up)
resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ecs-launch-template"
  # Using the user-specified AMI for us-east-1
  image_id      = "ami-09bf79a39d1ad39b5"
  instance_type = "t2.micro"
  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }
  vpc_security_group_ids = [aws_security_group.ecs_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
  EOF
  )
}

# Auto Scaling Group (manages our EC2 instances)
resource "aws_autoscaling_group" "ecs_asg" {
  name                = "ecs-asg"
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = [var.private_app_subnet_id]

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }
}

# ECS Task Definitions (one for each NGINX service)
resource "aws_ecs_task_definition" "nginx_a" {
  family                   = "nginx-a"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  container_definitions = jsonencode([{
    name      = "nginx-a"
    image     = "nginx:latest"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
    command = [
      "/bin/sh",
      "-c",
      "echo '<h1>Response from NGINX-A</h1>' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"
    ]
  }])
}

resource "aws_ecs_task_definition" "nginx_b" {
  family                   = "nginx-b"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  container_definitions = jsonencode([{
    name      = "nginx-b"
    image     = "nginx:latest"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
    command = [
      "/bin/sh",
      "-c",
      "echo '<h1>Response from NGINX-B</h1>' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"
    ]
  }])
}

# ECS Services (runs and manages our tasks)
resource "aws_ecs_service" "nginx_a" {
  name            = "nginx-a-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.nginx_a.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = [var.private_app_subnet_id]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_a.arn
    container_name   = "nginx-a"
    container_port   = 80
  }
}

resource "aws_ecs_service" "nginx_b" {
  name            = "nginx-b-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.nginx_b.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    subnets         = [var.private_app_subnet_id]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_b.arn
    container_name   = "nginx-b"
    container_port   = 80
  }
}

