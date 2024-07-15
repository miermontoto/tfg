# EFS File Systems

resource "aws_efs_file_system" "elastic_data" {
  creation_token = "elastic_data"

  tags = {
    Name = "tahoe-efs-elastic"
  }
}

resource "aws_efs_file_system" "kibana_data" {
  creation_token = "kibana_data"

  tags = {
    Name = "tahoe-efs-kibana"
  }
}

resource "aws_efs_file_system" "logstash_data" {
  creation_token = "logstash_data"

  tags = {
    Name = "tahoe-efs-logstash"
  }
}

# EFS Policies

resource "aws_efs_file_system_policy" "elastic_data_policy" {
  file_system_id = aws_efs_file_system.elastic_data.id
  policy         = data.aws_iam_policy_document.efs.json
}

resource "aws_efs_file_system_policy" "kibana_data_policy" {
  file_system_id = aws_efs_file_system.kibana_data.id
  policy         = data.aws_iam_policy_document.efs.json
}

resource "aws_efs_file_system_policy" "logstash_data_policy" {
  file_system_id = aws_efs_file_system.logstash_data.id
  policy         = data.aws_iam_policy_document.efs.json
}

# EFS Mount Targets

resource "aws_efs_mount_target" "mount_elastic_data" {
  file_system_id  = aws_efs_file_system.elastic_data.id
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.elastic.id]
}

resource "aws_efs_mount_target" "mount_kibana_data" {
  file_system_id  = aws_efs_file_system.kibana_data.id
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.kibana.id]
}

resource "aws_efs_mount_target" "mount_logstash_data" {
  file_system_id  = aws_efs_file_system.logstash_data.id
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.logstash.id]
}