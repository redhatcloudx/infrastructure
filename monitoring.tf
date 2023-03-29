# Resources for monitoring the cloud image directory.

locals {
  canary_name = "monitor-frontend"
}

# Add an S3 bucket to hold our canary results.
resource "aws_s3_bucket" "canary_bucket" {
  bucket = "cloudx-cid-frontend-canary-results"
}

# Create the synthetics canary that checks our front-end.
resource "aws_synthetics_canary" "monitor_frontend" {
  name                 = local.canary_name
  artifact_s3_location = "s3://${aws_s3_bucket.canary_bucket.id}/"
  execution_role_arn   = aws_iam_role.monitor_frontend.arn
  handler              = "frontend.handler"
  runtime_version      = "syn-python-selenium-1.3"
  start_canary         = true

  # Create this zip file with: zip -rv canary.zip python
  zip_file = "canary-scripts/canary.zip"

  schedule {
    expression = "rate(5 minutes)"
  }
}

# Create an IAM policy that allows the canary to do its work.
# Source: https://docs.aws.amazon.com/AmazonSynthetics/latest/APIReference/API_CreateCanary.html
data "aws_iam_policy_document" "monitor_frontend" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.canary_bucket.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.canary_bucket.bucket}/*"
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.canary_bucket.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.canary_bucket.bucket}/*"
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/cwsyn-${local.canary_name}-*"
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets",
      "xray:PutTraceSegments"
    ]

    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData"
    ]

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["CloudWatchSynthetics"]
    }

    resources = [
      "*"
    ]
  }
}

# Allow AWS Lambda to assume this role.
data "aws_iam_policy_document" "canary_bucket_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Load the IAM policy document into a policy that we can use with a role.
resource "aws_iam_policy" "monitor_frontend" {
  name = "monitor_frontend"

  policy = data.aws_iam_policy_document.monitor_frontend.json
}

# Create a role for the canary to use.
resource "aws_iam_role" "monitor_frontend" {
  name = "canary_monitor_frontend"

  managed_policy_arns = [aws_iam_policy.monitor_frontend.arn]
  assume_role_policy  = data.aws_iam_policy_document.canary_bucket_trust_policy.json
}

# Create a CloudWatch alarm that will notify us if the canary fails.
resource "aws_cloudwatch_metric_alarm" "monitor_frontend" {
  alarm_name          = "frontend-canary-alarm"
  comparison_operator = "LessThanThreshold"
  datapoints_to_alarm = "1"
  evaluation_periods  = "1"
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  treat_missing_data  = "breaching"
  dimensions = {
    CanaryName = aws_synthetics_canary.monitor_frontend.name
  }
  alarm_description = "Canary alarm for CID frontend"
  ok_actions        = [aws_sns_topic.monitor_frontend.arn]
  alarm_actions     = [aws_sns_topic.monitor_frontend.arn]
}

# Create an SNS topic that we can use to send notifications.
resource "aws_sns_topic" "monitor_frontend" {
  name = "monitor_frontend"
}

# Blast Major's inbox if something goes wrong
# TODO(major): Change this to a mailing list once we know it works.
resource "aws_sns_topic_subscription" "major_testing" {
  topic_arn = aws_sns_topic.monitor_frontend.arn
  protocol  = "email"
  endpoint  = "major@redhat.com"

  depends_on = [
    aws_sns_topic.monitor_frontend
  ]
}

# DNS records for upptime monitoring on GitHub Pages.
resource "aws_route53_record" "github_pages_upptime" {
  zone_id = data.aws_route53_zone.imagedirectory_cloud.zone_id
  name    = "status"
  type    = "CNAME"

  records = [
    "redhatcloudx.github.io",
  ]

  lifecycle {
    create_before_destroy = true
  }

  ttl = "3600"
}
