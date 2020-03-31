variable "endpoint_id" {
  type        = string
  description = "Your marbot endpoint ID (to get this value: select a Slack channel where marbot belongs to and send a message like this: \"@marbot show me my endpoint id\")."
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

variable "stage" {
  type        = string
  description = "marbot stage (never change this!)."
  default     = "v1"
}
