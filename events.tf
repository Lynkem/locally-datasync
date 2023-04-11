data "aws_iam_role" "scheduler" {
  name = "Amazon_EventBridge_Scheduler_LAMBDA_0f09e0cc02"
}

resource "aws_scheduler_schedule" "ds_agent_start" {
  for_each = local.locally_iterator

  name                         = "Locally${title(each.value)}DataSyncAgentStartup"
  group_name                   = aws_scheduler_schedule_group.datasync.name
  description                  = "Starts the EC2 instance hosting the Locally ${title(each.value)} DataSync Agent on a timed basis."
  schedule_expression          = local.sync_configs[each.value].agent_start_schedule
  schedule_expression_timezone = "US/Eastern"

  target {
    arn      = aws_lambda_function.onoff.arn
    role_arn = data.aws_iam_role.scheduler.arn
    input = jsonencode(
      {
        state = "on"
      }
    )

    retry_policy {
      maximum_event_age_in_seconds = 86400
      maximum_retry_attempts       = 185
    }
  }

  flexible_time_window {
    mode = "OFF"
  }
}

resource "aws_scheduler_schedule_group" "datasync" {
  name = "LocallyDataSyncSchedules"

  tags = {
    Name = "LocallyDataSyncSchedules"
  }
}
