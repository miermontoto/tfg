resource "aws_ecs_task_definition" "kafka" {
  family                   = "kafka"
  network_mode             = "awsvpc"
  requires_compatibilities = [var.launch_type]
  cpu                      = "2048"
  memory                   = "8192"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "zookeeper"
      image     = "confluentinc/cp-zookeeper:latest"
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = var.zookeeper_port
          hostPort      = var.zookeeper_port
        }
      ]
      environment = [
        { name = "ZOOKEEPER_CLIENT_PORT", value = tostring(var.zookeeper_port) },
        { name = "ZOOKEEPER_TICK_TIME", value = "2000" },
      ]
      logConfiguration = {
        logDriver = var.log_driver
        options = {
          "awslogs-group"         = var.log_group
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "zookeeper"
        }
      }
    },
    {
      name      = "kafka"
      image     = "confluentinc/cp-kafka:latest"
      cpu       = 1024
      memory    = 6144
      essential = true
      portMappings = [
        {
          containerPort = var.kafka_port
          hostPort      = var.kafka_port
        },
        {
          containerPort = 29092
          hostPort      = 29092
        }
      ]
      environment = [
        { name = "KAFKA_BROKER_ID", value = "1" },
        { name = "KAFKA_ZOOKEEPER_CONNECT", value = "127.0.0.1:${var.zookeeper_port}" },
        { name = "KAFKA_ADVERTISED_LISTENERS", value = "INTERNAL://127.0.0.1:29092,EXTERNAL://kafka.okticket.io:${var.kafka_port}" },
        { name = "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP", value = "INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT" },
        { name = "KAFKA_INTER_BROKER_LISTENER_NAME", value = "INTERNAL" },
        { name = "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR", value = "1" },
      ]
      logConfiguration = {
        logDriver = var.log_driver
        options = {
          "awslogs-group"         = var.log_group
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "kafka"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "kafka" {
  name                   = "kafka"
  cluster                = aws_ecs_cluster.cluster.id
  task_definition        = aws_ecs_task_definition.kafka.arn
  desired_count          = 1
  launch_type            = var.launch_type
  enable_execute_command = true

  network_configuration {
    subnets          = [aws_subnet.private.id]
    security_groups  = [aws_security_group.kafka.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.kafka.arn
    container_name   = "kafka"
    container_port   = var.kafka_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.zookeeper.arn
    container_name   = "zookeeper"
    container_port   = var.zookeeper_port
  }

  depends_on = [
    aws_lb_listener.kafka,
    aws_lb_listener.zookeeper
  ]
}

resource "aws_lb" "kafka" {
  name               = "tahoe-alb-kafka"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.kafka.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  # access_logs {
  #   bucket = aws_s3_bucket.access_logs.bucket
  #   prefix = "kafka"
  #   enabled = true
  # }

  tags = {
    Name = "tahoe-nlb-kafka"
  }
}

resource "aws_lb_target_group" "kafka" {
  name        = "tahoe-tg-kafka"
  port        = var.kafka_port
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    port                = var.kafka_port
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "zookeeper" {
  name        = "tahoe-zookeeper-tg"
  port        = var.zookeeper_port
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    port                = var.zookeeper_port
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "kafka" {
  load_balancer_arn = aws_lb.kafka.arn
  port              = var.kafka_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kafka.arn
  }
}

resource "aws_lb_listener" "zookeeper" {
  load_balancer_arn = aws_lb.kafka.arn
  port              = var.zookeeper_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.zookeeper.arn
  }
}

resource "aws_route53_record" "kafka" {
  zone_id = var.route53_zone_id
  name    = local.kafka_url
  type    = "A"

  alias {
    name                   = aws_lb.kafka.dns_name
    zone_id                = aws_lb.kafka.zone_id
    evaluate_target_health = false
  }
}
