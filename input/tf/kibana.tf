resource "aws_ecs_task_definition" "kibana" {
  family                   = "kibana"
  network_mode             = "awsvpc"
  requires_compatibilities = [var.launch_type]
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "kibana"
      image     = "docker.elastic.co/kibana/kibana:${var.stack_version}"
      cpu       = 2048
      memory    = 4096
      essential = true
      environment = [
        { name = "SERVER_NAME", value = "tahoe-kibana" },
        { name = "SERVER_PORT", value = tostring(var.kibana_port) },
        { name = "ELASTICSEARCH_HOSTS", value = "https://${local.elastic_url}:${var.elastic_port}" },
        { name = "SERVER_PUBLICBASEURL", value = "https://${local.kibana_url}:${var.kibana_port}" },
        { name = "ELASTICSEARCH_SSL_VERIFICATIONMODE", value = "none" },
        { name = "SERVER_SSL_ENABLED", value = "true" },
        { name = "ELASTICSEARCH_SSL_CERTIFICATEAUTHORITIES", value = "/usr/share/kibana/config/certs/ca.crt" },
        { name = "SERVER_SSL_CERTIFICATE", value = "/usr/share/kibana/config/certs/kibana.crt" },
        { name = "SERVER_SSL_KEY", value = "/usr/share/kibana/config/certs/kibana.key" },
        { name = "XPACK_SCREENSHOTTING_BROWSER_CHROMIUM_DISABLESANDBOX", value = "true" },
        { name = "ELASTICSEARCH_USERNAME", value = "kibana_system" }
      ]
      secrets = [
        {
          name      = "CA_CRT"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:ca.crt::"
        },
        {
          name      = "KIBANA_KEY"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:kibana.key::"
        },
        {
          name      = "KIBANA_CRT"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:kibana.crt::"
        },
        {
          name      = "ELASTICSEARCH_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:kibana_pass::"
        },
        {
          name      = "XPACK_ENCRYPTEDSAVEDOBJECTS_ENCRYPTIONKEY"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:xpack_key::"
        },
        {
          name      = "XPACK_SECURITY_ENCRYPTIONKEY"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:xpack_key::"
        },
        {
          name      = "XPACK_REPORTING_ENCRYPTIONKEY"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:xpack_key::"
        }
      ]
      entrypoint = [
        "/bin/sh",
        "-c",
        <<-EOT
        mkdir -p /usr/share/kibana/config/certs

        echo $CA_CRT | base64 -d > /usr/share/kibana/config/certs/ca.crt
        echo $KIBANA_KEY | base64 -d > /usr/share/kibana/config/certs/kibana.key
        echo $KIBANA_CRT | base64 -d > /usr/share/kibana/config/certs/kibana.crt

        chmod 400 /usr/share/kibana/config/certs/kibana.key
        sleep 15
        exec /usr/local/bin/kibana-docker
        EOT
      ]
      # mountPoints = [
      #   {
      #     sourceVolume = "kibana-data"
      #     containerPath = "/usr/share/kibana/data"
      #     readOnly = false
      #   }
      # ]
      portMappings = [
        {
          containerPort = var.kibana_port,
          hostPort      = var.kibana_port
        }
      ]
      logConfiguration = {
        logDriver = var.log_driver
        options = {
          "awslogs-group"         = var.log_group
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "kibana"
        }
      }
    }
  ])

  volume {
    name = "kibana-data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.kibana_data.id
      root_directory = "/"
    }
  }
}

resource "aws_ecs_service" "kibana" {
  name                   = "kibana"
  cluster                = aws_ecs_cluster.cluster.id
  task_definition        = aws_ecs_task_definition.kibana.arn
  desired_count          = 1
  launch_type            = var.launch_type
  enable_execute_command = true

  network_configuration {
    subnets         = [aws_subnet.private.id]
    security_groups = [aws_security_group.kibana.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.kibana.arn
    container_name   = "kibana"
    container_port   = var.kibana_port
  }

  depends_on = [aws_ecs_task_definition.kibana]
}

resource "aws_lb" "kibana" {
  name               = "tahoe-alb-kibana"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.kibana.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  access_logs {
    bucket  = aws_s3_bucket.access_logs.bucket
    prefix  = "kibana"
    enabled = true
  }
}

resource "aws_lb_target_group" "kibana" {
  name        = "tahoe-tg-kibana"
  port        = 5601
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    port                = var.kibana_port
    protocol            = "HTTPS"
    path                = "/api/status"
    interval            = 300
    timeout             = 60
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200-499"
  }
}

resource "aws_lb_listener" "kibana_https" {
  load_balancer_arn = aws_lb.kibana.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.kibana.arn

  default_action {
    type = "redirect"
    redirect {
      port        = tostring(var.kibana_port)
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "kibana" {
  load_balancer_arn = aws_lb.kibana.arn
  port              = var.kibana_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.kibana.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kibana.arn
  }

  depends_on = [aws_acm_certificate_validation.kibana]
}

resource "aws_route53_record" "kibana" {
  zone_id = var.route53_zone_id
  name    = local.kibana_url
  type    = "A"

  alias {
    name                   = aws_lb.kibana.dns_name
    zone_id                = aws_lb.kibana.zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "kibana" {
  domain_name       = local.kibana_url
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "kibana_acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.kibana.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

resource "aws_acm_certificate_validation" "kibana" {
  certificate_arn         = aws_acm_certificate.kibana.arn
  validation_record_fqdns = [for record in aws_route53_record.kibana_acm_validation : record.fqdn]
}
