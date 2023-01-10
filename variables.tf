variable "endpoint_id" {
  type        = string
  description = "Your marbot endpoint ID (to get this value: select a channel where marbot belongs to and send a message like this: \"@marbot show me my endpoint id\")."
}

variable "enabled" {
  type        = bool
  description = "Turn the module on or off"
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

variable "approximate_age_of_oldest_message_threshold" {
  type        = number
  description = "The maximum age (in seconds) of a message in the queue (set to -1 to disable)."
  default     = 600
}

variable "approximate_number_of_messages_visible_threshold" {
  type        = number
  description = "The maximum number of messages in the queue waiting for processing (set to -1 to disable)"
  default     = 10
}

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
