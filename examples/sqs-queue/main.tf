terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.48.0"
    }
  }
}

resource "aws_sqs_queue" "example" {
}
