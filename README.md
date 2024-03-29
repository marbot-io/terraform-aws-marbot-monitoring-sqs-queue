# SQS queue monitoring

Adds alarms to monitor SQS queue length and message age, and forwards them to Slack or Microsoft Teams managed by [marbot](https://marbot.io/).

## Usage

1. Create a new directory
2. Within the new directory, create a file `main.tf` with the following content:
```
provider "aws" {}

module "marbot-monitoring-sqs-queue" {
  source   = "marbot-io/marbot-monitoring-sqs-queue/aws"
  #version = "x.y.z"         # we recommend to pin the version

  endpoint_id = "" # to get this value, select a channel where marbot belongs to and send a message like this: "@marbot show me my endpoint id"
  queue_name  = "" # the queue name
}
```
3. Run the following commands:
```
terraform init
terraform apply
```

## Config via tags

You can also configure this module by tagging the SQS queue (requires v1.0.0 or higher). Tags take precedence over variables (tags override variables).

| tag key                                                            | default value                                                        | allowed values                                |
| ------------------------------------------------------------------ | -------------------------------------------------------------------- | ----------------------------------------------|
| `marbot`                                                           | on                                                                   | on,off                                        |
| `marbot:approximate-age-of-oldest-message`                         | variable `approximate_age_of_oldest_message`                         | static,off                                    |
| `marbot:approximate-age-of-oldest-message:threshold`               | variable `approximate_age_of_oldest_message_threshold`               | >= 0                                          |
| `marbot:approximate-age-of-oldest-message:period`                  | variable `approximate_age_of_oldest_message_period`                  | <= 86400 and multiple of 60                   |
| `marbot:approximate-age-of-oldest-message:evaluation-periods`      | variable `approximate_age_of_oldest_message_evaluation_periods`      | >= 1 and $period*$evaluation-periods <= 86400 |
| `marbot:approximate-number-of-messages-visible`                    | variable `approximate_number_of_messages_visible`                    | static,off                                    |
| `marbot:approximate-number-of-messages-visible:threshold`          | variable `approximate_number_of_messages_visible_threshold`          | >= 0                                          |
| `marbot:approximate-number-of-messages-visible:period`             | variable `approximate_number_of_messages_visible_period`             | <= 86400 and multiple of 60                   |
| `marbot:approximate-number-of-messages-visible:evaluation-periods` | variable `approximate_number_of_messages_visible_evaluation_periods` | >= 1 and $period*$evaluation-periods <= 86400 |

## Update procedure

1. Update the `version`
2. Run the following commands:
```
terraform get
terraform apply
```

## License
All modules are published under Apache License Version 2.0.

## About
A [marbot.io](https://marbot.io/) project. Engineered by [widdix](https://widdix.net).
