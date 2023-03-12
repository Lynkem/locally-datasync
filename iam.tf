data "aws_iam_policy_document" "datasync_trust" {
  statement {
    sid     = "TrustPolicyForDataSyncForLocallyData"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:datasync:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

data "aws_iam_policy_document" "datasync_service" {
  statement {
    sid    = "LocallyDataSyncBucketLevelAccess"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [data.aws_s3_bucket.target.arn]
  }

  statement {
    sid    = "LocallyDataSyncObjectLevelAccess"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
      "s3:PutObject",
      "s3:DeleteObjectTagging"
    ]
    resources = ["${data.aws_s3_bucket.target.arn}${local.target_path}/*"]
  }
}

resource "aws_iam_policy" "datasync_service" {
  name        = "LocallyDataSyncPolicy"
  description = "Policy for DataSync role to copy files from Locally s Google Storage into the lynkemprod S3 bucket."
  policy      = data.aws_iam_policy_document.datasync_service.json
  tags = {
    Name = "LocallyDataSyncPolicy"
  }
}

resource "aws_iam_role" "datasync_service" {
  name               = "LocallyDataSyncServiceRole"
  description        = "Service role for AWS DataSync for the Locally to lynkemprod S3 bucket transfer"
  assume_role_policy = data.aws_iam_policy_document.datasync_trust.json
  tags = {
    Name = "LocallyDataSyncServiceRole"
  }
}

resource "aws_iam_role_policy_attachment" "datasync_service" {
  role       = aws_iam_role.datasync_service.name
  policy_arn = aws_iam_policy.datasync_service.arn
}

data "aws_iam_policy_document" "lambda_onoff_trust" {
  statement {
    sid     = "TrustPolicyForLambdaRolesForLocallyDataSync"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_onoff" {
  statement {
    sid       = "AllowEc2DescribeInstances"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowEc2StopAndStartInstances"
    effect = "Allow"
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy" "cloudwatch_logs" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_onoff" {
  name        = "LocallyDataSyncAgentLambdaServicePolicy"
  description = "Service role policy for DataSync Agent power on/off Lambda"
  policy      = data.aws_iam_policy_document.lambda_onoff.json
}

resource "aws_iam_role" "lambda_onoff" {
  name               = "LocallyDataSyncAgentLambdaServiceRole"
  description        = "Service role for Lambda to allow turning DataSync agent instance on and off"
  assume_role_policy = data.aws_iam_policy_document.lambda_onoff_trust.json
}

resource "aws_iam_role_policy_attachment" "lambda_onoff" {
  for_each = toset([aws_iam_policy.lambda_onoff.arn, data.aws_iam_policy.cloudwatch_logs.arn])

  role       = aws_iam_role.lambda_onoff.name
  policy_arn = each.value
}
