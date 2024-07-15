resource "aws_security_group" "efs" {
  name        = "tahoe-efs-sg"
  description = "Permitir trafico a los servicios de EFS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 2049
    to_port     = 2049
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

resource "aws_security_group" "kafka" {
  vpc_id = aws_vpc.main.id
  name   = "tahoe-kafka-sg"
  description = "Permitir trafico a los stacks Kafka/Zookeeper"

  ingress {
    from_port   = var.kafka_port
    to_port     = var.kafka_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.zookeeper_port
    to_port     = var.zookeeper_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elastic" {
  vpc_id = aws_vpc.main.id
  name   = "tahoe-elastic-sg"
  description = "Permitir trafico a los nodos de Elasticsearch"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "kibana" {
  vpc_id = aws_vpc.main.id
  name   = "tahoe-kibana-sg"
  description = "Permitir trafico a los paneles de Kibana"

  ingress {
    from_port   = var.kibana_port
    to_port     = var.kibana_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_security_group" "logstash" {
  vpc_id = aws_vpc.main.id
  name   = "tahoe-logstash-sg"
  description = "Permitir trafico a los nodos de Logstash"

  ingress {
    from_port   = var.logstash_port
    to_port     = var.logstash_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
