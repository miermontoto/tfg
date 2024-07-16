resource "aws_secretsmanager_secret" "es_certs" {
  name        = "tahoe-certs-${local.hash}"
  description = "Claves para el data lake de OKT (codename: tahoe)"
}

resource "aws_secretsmanager_secret_version" "es_certs" {
  secret_id = aws_secretsmanager_secret.es_certs.id
  secret_string = jsonencode({
    "ca.crt"            = base64encode(file("certs/ca/ca.crt")),
    "es01.key"          = base64encode(file("certs/es01/es01.key")),
    "es01.crt"          = base64encode(file("certs/es01/es01.crt")),
    "kibana.crt"        = base64encode(file("certs/kibana/kibana.crt")),
    "kibana.key"        = base64encode(file("certs/kibana/kibana.key")),
    "xpack_key"         = local.random_key,
    "kibana_user"       = var.kibana_user,
    "kibana_pass"       = local.kibana_password,
    "elastic_pass"      = local.elastic_password,
    "health_check_user" = var.health_check_user,
    "health_check_pass" = local.health_check_password,
  })
}
