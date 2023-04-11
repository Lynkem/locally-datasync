resource "aws_datasync_location_object_storage" "source" {
  for_each = local.locally_iterator

  agent_arns      = [aws_datasync_agent.ec2.arn]
  server_hostname = local.sync_configs[each.value].source_hostname
  bucket_name     = local.sync_configs[each.value].source_bucket
  server_protocol = "HTTPS"
  server_port     = 443
  subdirectory    = local.sync_configs[each.value].source_path
  access_key      = var.googleapis_access_key
  secret_key      = var.googleapis_secret_key

  tags = {
    Name = "Locally ${local.title_keys[each.value]} DataSync Source"
  }
}

resource "aws_datasync_location_s3" "destination" {
  for_each = local.locally_iterator

  s3_bucket_arn    = data.aws_s3_bucket.target.arn
  subdirectory     = local.sync_configs[each.value].target_path
  agent_arns       = []
  s3_storage_class = "STANDARD"

  s3_config {
    bucket_access_role_arn = aws_iam_role.locally_datasync_service[each.value].arn
  }

  tags = {
    Name = "Locally ${local.title_keys[each.value]} DataSync Destination"
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

resource "aws_datasync_task" "locally" {
  for_each = local.locally_iterator

  name                     = "Locally ${local.title_keys[each.value]} Data Sync"
  source_location_arn      = aws_datasync_location_object_storage.source[each.value].arn
  destination_location_arn = aws_datasync_location_s3.destination[each.value].arn
  cloudwatch_log_group_arn = data.aws_cloudwatch_log_group.ds.arn

  dynamic "excludes" {
    for_each = toset(local.sync_configs[each.value].excludes)

    content {
      filter_type = excludes.value["filter_type"]
      value       = excludes.value["value"]
    }
  }

  schedule {
    schedule_expression = local.sync_configs[each.value].sync_schedule
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
    Name = "Locally ${local.title_keys[each.value]} DataSync"
  }
}

/*
resource "aws_datasync_task" "catalog_weekly" {
  source_location_arn      = aws_datasync_location_object_storage.catalog_source.arn
  destination_location_arn = aws_datasync_location_s3.destination["catalog"].arn
  name                     = "Locally Catalog Weekly Sync"
  cloudwatch_log_group_arn = data.aws_cloudwatch_log_group.ds.arn

  schedule {
    schedule_expression = "cron(0 2 ? * MON *)"
  }

  options {
    posix_permissions              = "NONE"
    gid                            = "NONE"
    uid                            = "NONE"
    atime                          = "BEST_EFFORT"
    bytes_per_second               = -1
    log_level                      = "BASIC"
    mtime                          = "PRESERVE"
    overwrite_mode                 = "ALWAYS"
    preserve_deleted_files         = "PRESERVE"
    preserve_devices               = "NONE"
    security_descriptor_copy_flags = "NONE"
    task_queueing                  = "ENABLED"
    transfer_mode                  = "CHANGED"
    verify_mode                    = "ONLY_FILES_TRANSFERRED"
  }

  tags = {
    Name = "Locally Catalog DailySync"
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
*/
data "aws_cloudwatch_log_group" "ds" {
  name = "/aws/datasync"
}
