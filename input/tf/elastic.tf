resource "aws_ecs_task_definition" "elastic" {
  family                   = "elastic"
  network_mode             = "awsvpc"
  requires_compatibilities = [var.launch_type]
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "es01"
      image     = "docker.elastic.co/elasticsearch/elasticsearch:${var.stack_version}"
      cpu       = 2048
      memory    = 4096
      essential = true
      environment = [
        { name = "cluster.name", value = var.cluster_name },
        { name = "xpack.security.enabled", value = "true" },
        { name = "xpack.security.http.ssl.enabled", value = "true" },
        { name = "xpack.security.transport.ssl.enabled", value = "true" },
        { name = "xpack.security.http.ssl.key", value = "/usr/share/elasticsearch/config/certs/es01.key" },
        { name = "xpack.security.http.ssl.certificate", value = "/usr/share/elasticsearch/config/certs/es01.crt" },
        { name = "xpack.security.http.ssl.certificate_authorities", value = "/usr/share/elasticsearch/config/certs/ca.crt" },
        { name = "xpack.security.transport.ssl.key", value = "/usr/share/elasticsearch/config/certs/es01.key" },
        { name = "xpack.security.transport.ssl.certificate", value = "/usr/share/elasticsearch/config/certs/es01.crt" },
        { name = "xpack.security.transport.ssl.certificate_authorities", value = "/usr/share/elasticsearch/config/certs/ca.crt" },
        { name = "discovery.type", value = "single-node" },
        # { name = "ES_JAVA_OPTS", value = "-Xms4g -Xmx4g" },
        { name = "bootstrap.memory_lock", value = "true" },
        # { name = "logger.level", value = "WARN" },
        { name = "xpack.security.authc.anonymous.username", value = var.health_check_user },
        { name = "xpack.security.authc.anonymous.roles", value = "monitoring_user" },
        { name = "xpack.security.authc.anonymous.authz_exception", value = "true" }
      ]
      secrets = [
        {
          name      = "CA_CRT"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:ca.crt::"
        },
        {
          name      = "ES01_KEY"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:es01.key::"
        },
        {
          name      = "ES01_CRT"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:es01.crt::"
        },
        {
          name      = "ELASTIC_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:elastic_pass::"
        },
        {
          name      = "HEALTH_CHECK_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:health_check_pass::"
        },
        {
          name      = "KIBANA_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:kibana_pass::"
        },
        {
          name      = "KIBANA_USER"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:kibana_user::"
        },
        {
          name      = "HEALTH_CHECK_USER"
          valueFrom = "${aws_secretsmanager_secret.es_certs.arn}:health_check_user::"
        }
      ]
      entrypoint = [
        "/bin/sh",
        "-c",
        <<-EOT
        #!/bin/bash
        set -e

        echo "Configurando credenciales..."
        mkdir -p /usr/share/elasticsearch/config/certs
        echo $CA_CRT | base64 -d > /usr/share/elasticsearch/config/certs/ca.crt
        echo $ES01_KEY | base64 -d > /usr/share/elasticsearch/config/certs/es01.key
        echo $ES01_CRT | base64 -d > /usr/share/elasticsearch/config/certs/es01.crt
        chmod 400 /usr/share/elasticsearch/config/certs/es01.key

        # establecer vm.max_map_count
        echo "Estableciendo vm.max_map_count..."
        sysctl -w vm.max_map_count=262144

        # iniciar elasticsearch
        echo "Iniciando Elasticsearch..."
        /usr/local/bin/docker-entrypoint.sh &

        # esperar a que elasticsearch este listo
        echo "Esperando a que Elasticsearch este listo..."
        until curl -s -XGET https://localhost:9200 -u elastic:$ELASTIC_PASSWORD -k > /dev/null; do
          sleep 1
        done

        # crear usuarios
        echo "Creando usuarios..."
        curl -s -X POST -u "elastic:$ELASTIC_PASSWORD" -H "Content-Type: application/json" https://localhost:9200/_security/user/kibana_system/_password -d '{"password": "$KIBANA_PASSWORD"}'
        curl -s -X POST -u elastic:$ELASTIC_PASSWORD -H "Content-Type: application/json" https://localhost:9200/_security/user/$HEALTH_CHECK_USER -d '{"password": "$HEALTH_CHECK_PASS", "roles": ["monitoring_user"]}'

        wait
        EOT
      ]
      # mountPoints = [
      #   {
      #     sourceVolume  = "elastic-data"
      #     containerPath = "/usr/share/elasticsearch/data"
      #     readOnly      = false
      #   }
      # ]
      portMappings = [
        {
          containerPort = var.elastic_port,
          hostPort      = var.elastic_port
        }
      ]
      logConfiguration = {
        logDriver = var.log_driver
        options = {
          "awslogs-group"         = var.log_group
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "elastic"
        }
      }
      ulimits = [
        {
          name      = "memlock"
          softLimit = -1
          hardLimit = -1
        },
        {
          name      = "nofile"
          softLimit = 65536
          hardLimit = 65536
        }
      ]
    }
  ])

  volume {
    name = "elastic-data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.elastic_data.id
      root_directory = "/"
    }
  }
}

resource "aws_ecs_service" "elastic" {
  name                   = "elastic"
  cluster                = aws_ecs_cluster.cluster.id
  task_definition        = aws_ecs_task_definition.elastic.arn
  desired_count          = 1
  launch_type            = var.launch_type
  enable_execute_command = true

  network_configuration {
    subnets          = [aws_subnet.private.id]
    security_groups  = [aws_security_group.elastic.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.elastic.arn
    container_name   = "es01"
    container_port   = var.elastic_port
  }

  depends_on = [
    aws_lb_listener.elastic,
    aws_ecs_task_definition.elastic
  ]
}

resource "aws_lb" "elastic" {
  name               = "tahoe-alb-elastic"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elastic.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  access_logs {
    bucket  = aws_s3_bucket.access_logs.bucket
    prefix  = "elastic"
    enabled = true
  }
}

resource "aws_lb_target_group" "elastic" {
  name        = "tahoe-tg-elastic"
  port        = var.elastic_port
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTPS"
    matcher             = "200"
    interval            = 300
    timeout             = 60
    healthy_threshold   = 2
    unhealthy_threshold = 5
    port                = tostring(var.elastic_port)
  }
}

resource "aws_lb_listener" "elastic" {
  load_balancer_arn = aws_lb.elastic.arn
  port              = var.elastic_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.elastic.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.elastic.arn
  }
}

resource "aws_lb_listener" "elastic_https" {
  load_balancer_arn = aws_lb.elastic.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.elastic.arn

  default_action {
    type = "redirect"
    redirect {
      port        = tostring(var.elastic_port)
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_acm_certificate" "elastic" {
  domain_name       = local.elastic_url
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "elastic" {
  zone_id = var.route53_zone_id
  name    = local.elastic_url
  type    = "A"

  alias {
    name                   = aws_lb.elastic.dns_name
    zone_id                = aws_lb.elastic.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "elastic_validation" {
  for_each = {
    for dvo in aws_acm_certificate.elastic.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "elastic" {
  certificate_arn         = aws_acm_certificate.elastic.arn
  validation_record_fqdns = [for record in aws_route53_record.elastic_validation : record.fqdn]
}
