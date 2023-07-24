terraform {
  required_version = ">= 0.12.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.48.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.2"
    }
  }
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_sqs_queue" "queue" {
  name = var.queue_name
}

locals {
  topic_arn = var.create_topic == false ? var.topic_arn : join("", aws_sns_topic.marbot[*].arn)
  enabled   = var.enabled && lookup(data.aws_sqs_queue.queue.tags, "marbot", "on") != "off"

  approximate_age_of_oldest_message                        = lookup(data.aws_sqs_queue.queue.tags, "marbot:approximate-age-of-oldest-message", var.approximate_age_of_oldest_message)
  approximate_age_of_oldest_message_threshold              = try(tonumber(lookup(data.aws_sqs_queue.queue.tags, "marbot:approximate-age-of-oldest-message:threshold", var.approximate_age_of_oldest_message_threshold)), var.approximate_age_of_oldest_message_threshold)
  approximate_age_of_oldest_message_period_raw             = try(tonumber(lookup(data.aws_sqs_queue.queue.tags, "marbot:approximate-age-of-oldest-message:period", var.approximate_age_of_oldest_message_period)), var.approximate_age_of_oldest_message_period)
  approximate_age_of_oldest_message_period                 = min(max(floor(local.approximate_age_of_oldest_message_period_raw / 60) * 60, 60), 86400)
  approximate_age_of_oldest_message_evaluation_periods_raw = try(tonumber(lookup(data.aws_sqs_queue.queue.tags, "marbot:approximate-age-of-oldest-message:evaluation-periods", var.approximate_age_of_oldest_message_evaluation_periods)), var.approximate_age_of_oldest_message_evaluation_periods)
  approximate_age_of_oldest_message_evaluation_periods     = min(max(local.approximate_age_of_oldest_message_evaluation_periods_raw, 1), floor(86400 / local.approximate_age_of_oldest_message_period))

  approximate_number_of_messages_visible                        = lookup(data.aws_sqs_queue.queue.tags, "marbot:approximate-number-of-messages-visible", var.approximate_number_of_messages_visible)
  approximate_number_of_messages_visible_threshold              = try(tonumber(lookup(data.aws_sqs_queue.queue.tags, "marbot:approximate-number-of-messages-visible:threshold", var.approximate_number_of_messages_visible_threshold)), var.approximate_number_of_messages_visible_threshold)
  approximate_number_of_messages_visible_period_raw             = try(tonumber(lookup(data.aws_sqs_queue.queue.tags, "marbot:approximate-number-of-messages-visible:period", var.approximate_number_of_messages_visible_period)), var.approximate_number_of_messages_visible_period)
  approximate_number_of_messages_visible_period                 = min(max(floor(local.approximate_number_of_messages_visible_period_raw / 60) * 60, 60), 86400)
  approximate_number_of_messages_visible_evaluation_periods_raw = try(tonumber(lookup(data.aws_sqs_queue.queue.tags, "marbot:approximate-number-of-messages-visible:evaluation-periods", var.approximate_number_of_messages_visible_evaluation_periods)), var.approximate_number_of_messages_visible_evaluation_periods)
  approximate_number_of_messages_visible_evaluation_periods     = min(max(local.approximate_number_of_messages_visible_evaluation_periods_raw, 1), floor(86400 / local.approximate_number_of_messages_visible_period))
}

##########################################################################
#                                                                        #
#                                 TOPIC                                  #
#                                                                        #
##########################################################################

resource "aws_sns_topic" "marbot" {
  count = (var.create_topic && local.enabled) ? 1 : 0

  name_prefix = "marbot"
  tags        = var.tags
}

resource "aws_sns_topic_policy" "marbot" {
  count = (var.create_topic && local.enabled) ? 1 : 0

  arn    = join("", aws_sns_topic.marbot[*].arn)
  policy = data.aws_iam_policy_document.topic_policy.json
}

data "aws_iam_policy_document" "topic_policy" {
  statement {
    sid       = "Sid1"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [join("", aws_sns_topic.marbot[*].arn)]

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
    resources = [join("", aws_sns_topic.marbot[*].arn)]

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
  count      = (var.create_topic && local.enabled) ? 1 : 0

  topic_arn              = join("", aws_sns_topic.marbot[*].arn)
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
  },
  "throttlePolicy": {
    "maxReceivesPerSecond": 1
  }
}
JSON
}



resource "aws_cloudwatch_event_rule" "monitoring_jump_start_connection" {
  depends_on = [aws_sns_topic_subscription.marbot]
  count      = (var.module_version_monitoring_enabled && local.enabled) ? 1 : 0

  name                = "marbot-sqs-queue-connection-${random_id.id8.hex}"
  description         = "Monitoring Jump Start connection (created by marbot)"
  schedule_expression = "rate(30 days)"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "monitoring_jump_start_connection" {
  count = (var.module_version_monitoring_enabled && local.enabled) ? 1 : 0

  rule      = join("", aws_cloudwatch_event_rule.monitoring_jump_start_connection[*].name)
  target_id = "marbot"
  arn       = local.topic_arn
  input     = <<JSON
{
  "Type": "monitoring-jump-start-tf-connection",
  "Module": "sqs-queue",
  "Version": "1.0.0",
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
  count      = (local.approximate_age_of_oldest_message == "static" && local.enabled) ? 1 : 0

  alarm_name          = "marbot-sqs-queue-message-age-${random_id.id8.hex}"
  alarm_description   = "Queue contains old messages. Is message processing failing or is the message procesing capacity too low? (created by marbot)"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  statistic           = "Maximum"
  period              = local.approximate_age_of_oldest_message_period
  evaluation_periods  = local.approximate_age_of_oldest_message_evaluation_periods
  comparison_operator = "GreaterThanThreshold"
  threshold           = local.approximate_age_of_oldest_message_threshold
  alarm_actions       = [local.topic_arn]
  ok_actions          = [local.topic_arn]
  dimensions = {
    QueueName = var.queue_name
  }
  treat_missing_data = "notBreaching"
  tags               = var.tags
}



resource "aws_cloudwatch_metric_alarm" "approximate_number_of_messages_visible" {
  depends_on = [aws_sns_topic_subscription.marbot]
  count      = (local.approximate_number_of_messages_visible == "static" && local.enabled) ? 1 : 0

  alarm_name          = "marbot-sqs-queue-length-${random_id.id8.hex}"
  alarm_description   = "Queue contains too many messages. Is message processing failing or is the message procesing capacity too low? (created by marbot)"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = local.approximate_number_of_messages_visible_period
  evaluation_periods  = local.approximate_number_of_messages_visible_evaluation_periods
  comparison_operator = "GreaterThanThreshold"
  threshold           = local.approximate_number_of_messages_visible_threshold
  alarm_actions       = [local.topic_arn]
  ok_actions          = [local.topic_arn]
  dimensions = {
    QueueName = var.queue_name
  }
  treat_missing_data = "notBreaching"
  tags               = var.tags
}
