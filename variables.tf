# We can not only check the var.topic_arn !="" because of the Terraform error:  The "count" value depends on resource attributes that cannot be determined until apply, so Terraform cannot predict how many instances will be created.
variable "create_topic" {
  type        = bool
  description = "Create SNS topic? If set to false you must set topic_arn as well!"
  default     = true
}

variable "topic_arn" {
  type        = string
  description = "Optional SNS topic ARN if create_topic := false (usually the output of the modules marbot-monitoring-basic or marbot-standalone-topic)."
  default     = ""
}

variable "stage" {
  type        = string
  description = "marbot stage (never change this!)."
  default     = "v1"
}

variable "endpoint_id" {
  type        = string
  description = "Your marbot endpoint ID (to get this value: select a channel where marbot belongs to and send a message like this: \"@marbot show me my endpoint id\")."
}

variable "enabled" {
  type        = bool
  description = "Turn the module on or off"
  default     = true
}

variable "module_version_monitoring_enabled" {
  type        = bool
  description = "Report the module version back to marbot to notify if updates are available."
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "queue_name" {
  type        = string
  description = "The SQS queue name that you want to monitor."
}



variable "approximate_age_of_oldest_message" {
  type        = string
  description = "Old messages (static|off)."
  default     = "static"
}

variable "approximate_age_of_oldest_message_threshold" {
  type        = number
  description = "The maximum age (in seconds) of a message in the queue (>= 0)."
  default     = 600
}

variable "approximate_age_of_oldest_message_period" {
  type        = number
  description = "The period in seconds over which the specified statistic is applied (<= 86400 and multiple of 60)."
  default     = 60
}

variable "approximate_age_of_oldest_message_evaluation_periods" {
  type        = number
  description = "The number of periods over which data is compared to the specified threshold (>= 1 and $period*$evaluation_periods <= 86400)."
  default     = 1
}



variable "approximate_number_of_messages_visible" {
  type        = string
  description = "Waiting messages (static|off)."
  default     = "static"
}

variable "approximate_number_of_messages_visible_threshold" {
  type        = number
  description = "The maximum number of messages in the queue waiting for processing (>= 0)."
  default     = 10
}

variable "approximate_number_of_messages_visible_period" {
  type        = number
  description = "The period in seconds over which the specified statistic is applied (<= 86400 and multiple of 60)."
  default     = 60
}

variable "approximate_number_of_messages_visible_evaluation_periods" {
  type        = number
  description = "The number of periods over which data is compared to the specified threshold (>= 1 and $period*$evaluation_periods <= 86400)."
  default     = 1
}
