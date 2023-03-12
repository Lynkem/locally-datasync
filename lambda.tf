data "archive_file" "lambda_src" {
  type        = "zip"
  source_file = "${path.module}/lambda_src/instance_switch.py"
  output_path = "${path.module}/lambda_src/instance_switch.zip"
}

resource "aws_lambda_function" "onoff" {
  function_name    = "DataSyncAgentPowerControl"
  role             = aws_iam_role.lambda_onoff.arn
  description      = "Function to stop or start the EC2 DataSync Agent.  Input event should contain a key called 'state' which should be either 'on' or 'off'"
  filename         = "${path.module}/lambda_src/instance_switch.zip"
  handler          = "instance_switch.handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.lambda_src.output_base64sha256

  tags = {
    Name = "DataSyncAgentPowerControl"
  }
}
