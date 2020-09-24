terraform {
  required_version = "~> 0.12"
  required_providers {
    aws    = ">= 2.48.0, < 3"
    random = "~> 2.2"
  }
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

##########################################################################
#                                                                        #
#                                 TOPIC                                  #
#                                                                        #
##########################################################################

resource "aws_sns_topic" "marbot" {
  count = var.enabled ? 1 : 0

  name_prefix = "marbot"
  tags        = var.tags
}

resource "aws_sns_topic_policy" "marbot" {
  count = var.enabled ? 1 : 0

  arn    = join("", aws_sns_topic.marbot.*.arn)
  policy = data.aws_iam_policy_document.topic_policy.json
}

data "aws_iam_policy_document" "topic_policy" {
  statement {
    sid       = "Sid1"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [join("", aws_sns_topic.marbot.*.arn)]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
      ]
    }
  }

  statement {
    sid       = "Sid2"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [join("", aws_sns_topic.marbot.*.arn)]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_subscription" "marbot" {
  depends_on = [aws_sns_topic_policy.marbot]
  count      = var.enabled ? 1 : 0

  topic_arn              = join("", aws_sns_topic.marbot.*.arn)
  protocol               = "https"
  endpoint               = "https://api.marbot.io/${var.stage}/endpoint/${var.endpoint_id}"
  endpoint_auto_confirms = true
  delivery_policy        = <<JSON
{
  "healthyRetryPolicy": {
    "minDelayTarget": 1,
    "maxDelayTarget": 60,
    "numRetries": 100,
    "numNoDelayRetries": 0,
    "backoffFunction": "exponential"
  }
}
JSON
}



resource "aws_cloudwatch_event_rule" "monitoring_jump_start_connection" {
  depends_on = [aws_sns_topic_subscription.marbot]
  count      = var.enabled ? 1 : 0

  name                = "marbot-sqs-queue-connection-${random_id.id8.hex}"
  description         = "Monitoring Jump Start connection (created by marbot)"
  schedule_expression = "rate(30 days)"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "monitoring_jump_start_connection" {
  count = var.enabled ? 1 : 0

  rule      = join("", aws_cloudwatch_event_rule.monitoring_jump_start_connection.*.name)
  target_id = "marbot"
  arn       = join("", aws_sns_topic.marbot.*.arn)
  input     = <<JSON
{
  "Type": "monitoring-jump-start-tf-connection",
  "Module": "sqs-queue",
  "Version": "0.5.0",
  "Partition": "${data.aws_partition.current.partition}",
  "AccountId": "${data.aws_caller_identity.current.account_id}",
  "Region": "${data.aws_region.current.name}"
}
JSON
}

##########################################################################
#                                                                        #
#                                 ALARMS                                 #
#                                                                        #
##########################################################################

resource "random_id" "id8" {
  byte_length = 8
}



resource "aws_cloudwatch_metric_alarm" "approximate_age_of_oldest_message" {
  depends_on = [aws_sns_topic_subscription.marbot]
  count      = (var.approximate_age_of_oldest_message_threshold >= 0 && var.enabled) ? 1 : 0

  alarm_name          = "marbot-sqs-queue-message-age-${random_id.id8.hex}"
  alarm_description   = "Queue contains old messages. Is message processing failing or is the message procesing capacity too low? (created by marbot)"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.approximate_age_of_oldest_message_threshold
  alarm_actions       = [join("", aws_sns_topic.marbot.*.arn)]
  ok_actions          = [join("", aws_sns_topic.marbot.*.arn)]
  dimensions = {
    QueueName = var.queue_name
  }
  treat_missing_data = "notBreaching"
  tags               = var.tags
}



resource "aws_cloudwatch_metric_alarm" "approximate_number_of_messages_visible" {
  depends_on = [aws_sns_topic_subscription.marbot]
  count      = (var.approximate_number_of_messages_visible_threshold >= 0 && var.enabled) ? 1 : 0

  alarm_name          = "marbot-sqs-queue-length-${random_id.id8.hex}"
  alarm_description   = "Queue contains too many messages. Is message processing failing or is the message procesing capacity too low? (created by marbot)"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.approximate_number_of_messages_visible_threshold
  alarm_actions       = [join("", aws_sns_topic.marbot.*.arn)]
  ok_actions          = [join("", aws_sns_topic.marbot.*.arn)]
  dimensions = {
    QueueName = var.queue_name
  }
  treat_missing_data = "notBreaching"
  tags               = var.tags
}
