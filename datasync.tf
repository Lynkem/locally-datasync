resource "aws_datasync_location_s3" "target" {
  s3_bucket_arn    = data.aws_s3_bucket.target.arn
  subdirectory     = "${local.target_path}/"
  agent_arns       = []
  s3_storage_class = "STANDARD"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_service.arn
  }

  tags = {
    Name = "Locally DataSync Target"
  }
}

resource "aws_datasync_location_object_storage" "source" {
  agent_arns      = [aws_datasync_agent.ec2.arn]
  server_hostname = "storage.googleapis.com"
  bucket_name     = "brandslice-stock"
  server_protocol = "HTTPS"
  server_port     = 443
  subdirectory    = "/brandslice-stock/"
  access_key      = var.googleapis_access_key
  secret_key      = var.googleapis_secret_key


  tags = {
    Name = "Locally DataSync Source"
  }
}


resource "aws_vpc_endpoint" "ds" {
  service_name        = "com.amazonaws.us-east-1.datasync"
  vpc_id              = data.aws_vpc.main.id
  security_group_ids  = [aws_security_group.agent.id]
  subnet_ids          = [data.aws_subnet.use1a.id]
  private_dns_enabled = true
  vpc_endpoint_type   = "Interface"

  tags = {
    Name = "locally-datasync-endpoint"
  }
}

data "aws_network_interface" "ds_endpoint" {
  id = tolist(aws_vpc_endpoint.ds.network_interface_ids)[0]
}

resource "aws_datasync_agent" "ec2" {
  name                  = "Locally DataSync Agent"
  security_group_arns   = [aws_security_group.agent.arn]
  subnet_arns           = [data.aws_subnet.use1a.arn]
  vpc_endpoint_id       = aws_vpc_endpoint.ds.id
  private_link_endpoint = data.aws_network_interface.ds_endpoint.private_ip
  ip_address            = aws_eip.agent.public_ip
  # activation_key        = var.datasync_activation_key

  tags = {
    Name = "Locally DataSync Agent"
  }
}

resource "aws_datasync_task" "daily" {
  destination_location_arn = aws_datasync_location_s3.target.arn
  source_location_arn      = aws_datasync_location_object_storage.source.arn
  name                     = "Locally Daily Sync"
  cloudwatch_log_group_arn = data.aws_cloudwatch_log_group.ds.arn

  schedule {
    schedule_expression = "cron(15 8 * * ? *)"
  }

  excludes {
    filter_type = "SIMPLE_PATTERN"
    value       = "/master-000000000000.csv"
  }

  options {
    atime                          = "BEST_EFFORT"
    bytes_per_second               = -1
    gid                            = "NONE"
    log_level                      = "BASIC"
    mtime                          = "PRESERVE"
    overwrite_mode                 = "ALWAYS"
    posix_permissions              = "NONE"
    preserve_deleted_files         = "PRESERVE"
    preserve_devices               = "NONE"
    security_descriptor_copy_flags = "NONE"
    task_queueing                  = "ENABLED"
    transfer_mode                  = "CHANGED"
    uid                            = "NONE"
    verify_mode                    = "ONLY_FILES_TRANSFERRED"
  }

  tags = {
    Name = "Locally Daily Sync"
  }
}

data "aws_cloudwatch_log_group" "ds" {
  name = "/aws/datasync"
}
