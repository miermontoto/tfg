variable "log_group" {default = "/ecs/elastic-services"}
variable "log_driver" {default = "awslogs"}

variable "launch_type" {default = "FARGATE"}
variable "cluster_name" {default = "tahoe"}
variable "region" {default = "eu-north-1"}
variable "domain_name" {default = "okticket.io"}
variable "route53_zone_id" {default = "Z01935951GG68PCUSU149"}
variable "elb_account_id" {default = "897822967062"}

variable "stack_version" {
	type = string
	default = "8.12.2"
	description = "Version de la pila ELK"
}
variable "kibana_user" {
	type = string
	default = "kibana_user"
	description = "Nombre de usuario de elsatic para Kibana"
}
variable "health_check_user" {
	type = string
	default = "aws_health_check_tahoe"
	description = "Nombre del usuario de health-check"
}

locals {
	health_check_password = random_string.random_service_password.result
	kibana_password = random_string.random_service_password.result
	random_key = random_string.random_key.result
	elastic_password = random_string.random_password.result
	hash = random_string.hash.result

	kibana_url = "tahoe.${var.domain_name}"
	elastic_url = "elastic.${var.domain_name}"
	kafka_url = "kafka.${var.domain_name}"
	logstash_url = "logstash.${var.domain_name}"
}

resource "random_string" "random_key" {
	length  = 64
	special = false
}
resource "random_string" "random_password" {
	length  = 16
	special = false
}
resource "random_string" "random_service_password" {
	length  = 16
	special = false
}
resource "random_string" "hash" {
	length = 4
	special = false
	upper = false
}

variable "zookeeper_port" {default = 2181}
variable "kafka_port" {default = 9092}
variable "elastic_port" {default = 9200}
variable "kibana_port" {default = 5601}
variable "logstash_port" {default = 5044}
