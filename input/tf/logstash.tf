resource "aws_ecs_task_definition" "logstash" {
  family                   = "logstash"
  network_mode             = "awsvpc"
  requires_compatibilities = [var.launch_type]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "logstash"
      image     = "docker.elastic.co/logstash/logstash:${var.stack_version}"
      cpu       = 1024
      memory    = 2048
      essential = true
      environment = [
        { name = "XPACK_MONITORING_ELASTICSEARCH_HOSTS", value = "https://${local.elastic_url}:${var.elastic_port}" },
        { name = "XPACK_MONITORING_ENABLED", value = "true" },
        { name = "CONFIG_RELOAD_AUTOMATIC", value = "true" },
        { name = "CONFIG_RELOAD_INTERVAL", value = "60" },
        { name = "ELASTICSEARCH_USERNAME", value = "elastic" },
      ]
      secrets = [
        {
          name      = "ELASTICSEARCH_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:elastic_pass::"
        },
        {
          name      = "CA_CERT"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:ca.crt::"
        }
      ]
      entrypoint = [
        "/bin/sh",
        "-c",
        <<-EOT
        cat <<EOF > /usr/share/logstash/config/logstash.conf
        input {
          kafka {
            bootstrap_servers => "http://${local.kafka_url}:${var.kafka_port}"
            topics => ["kafka"]
          }
        }
        output {
          elasticsearch {
            hosts => ["https://${local.elastic_url}:${var.elastic_port}"]
            user => "elastic"
            password => "$ELASTIC_PASSWORD"
            ssl => true
            cacert => "/usr/share/logstash/config/ca.crt"
          }
        }
        EOF

        echo $CA_CERT | base64 -d > /usr/share/logstash/config/ca.crt

        exec /usr/local/bin/docker-entrypoint
        EOT
      ]
      portMappings = [
        {
          containerPort = var.logstash_port,
          hostPort      = var.logstash_port
        }
      ]
      # mountPoints = [
      #   {
      #     sourceVolume  = "logstash-data"
      #     containerPath = "/usr/share/logstash/data"
      #     readOnly      = false
      #   }
      # ]
      logConfiguration = {
        logDriver = var.log_driver
        options = {
          "awslogs-group"         = var.log_group
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "logstash"
        }
      }
    }
  ])

  volume {
    name = "logstash-data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.logstash_data.id
      root_directory = "/"
    }
  }
}

resource "aws_ecs_service" "logstash" {
  name            = "logstash"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.logstash.arn
  desired_count   = 1
  launch_type     = var.launch_type

  network_configuration {
    subnets         = [aws_subnet.private.id]
    security_groups = [aws_security_group.logstash.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.logstash.arn
    container_name   = "logstash"
    container_port   = var.logstash_port
  }

  depends_on = [aws_ecs_task_definition.logstash]
}

resource "aws_lb" "logstash" {
  name               = "tahoe-alb-logstash"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.logstash.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  access_logs {
    bucket  = aws_s3_bucket.access_logs.bucket
    prefix  = "logstash"
    enabled = true
  }
}

resource "aws_lb_target_group" "logstash" {
  name        = "tahoe-tg-logstash"
  port        = var.logstash_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = var.logstash_port
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }
}

resource "aws_lb_listener" "logstash" {
  load_balancer_arn = aws_lb.logstash.arn
  port              = var.logstash_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.logstash.arn
  }
}

resource "aws_route53_record" "logstash" {
  zone_id = var.route53_zone_id
  name    = local.logstash_url
  type    = "A"

  alias {
    name                   = aws_lb.logstash.dns_name
    zone_id                = aws_lb.logstash.zone_id
    evaluate_target_health = false
  }
}
