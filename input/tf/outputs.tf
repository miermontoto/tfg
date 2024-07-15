output "passwords" {
	value = "e: ${local.elastic_password}, k: ${local.kibana_password}, h: ${local.health_check_password}"
}

output "url_elastic" {
  value = "https://${aws_lb.elastic.dns_name}:${var.elastic_port} (https://${local.elastic_url}:${var.elastic_port})"
}

output "url_kibana" {
  value = "https://${aws_lb.kibana.dns_name}:${var.kibana_port} (https://${local.kibana_url}:${var.kibana_port})"
}

output "url_kafka" {
  value = "http://${aws_lb.kafka.dns_name}:${var.kafka_port} (http://${local.kafka_url}:${var.kafka_port})"
}

output "hash" {
	value = local.hash
}
