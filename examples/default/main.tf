terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.48.0"
    }
  }
}

module "marbot-monitoring-sqs-queue" {
  source = "../../"

  endpoint_id = var.endpoint_id
  queue_name = var.queue_name
}