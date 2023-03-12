data "aws_iam_role" "scheduler" {
  name = "Amazon_EventBridge_Scheduler_LAMBDA_0f09e0cc02"
}

resource "aws_scheduler_schedule" "agent_start" {
  name                         = "DataSyncAgentStartup"
  group_name                   = aws_scheduler_schedule_group.datasync.name
  description                  = "Starts the EC2 instance hosting the Locally DataSync Agent on a timed basis"
  schedule_expression          = "cron(0 8 * * ? *)"
  schedule_expression_timezone = "UTC"

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
