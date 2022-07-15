# terraform-aws-sns

## Usage

```terraform
module "sns" {
  source = "git@github.com:oozou/terraform-aws-sns.git?ref=<version>"

  prefix       = var.generics_info["prefix"]
  environment  = var.generics_info["environment"]
  name         = var.generics_info["name"]
  display_name = "God of Gor Don" # Default is "", name appear with message; no affect to resource arn

  # https://docs.aws.amazon.com/sns/latest/dg/sns-message-delivery-retries.html
  override_topic_deliver_policy = jsonencode({ # Default is "", use to override defualt topic deliver policy
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 10,
        maxDelayTarget     = 10,
        numRetries         = 10,
        numMaxDelayRetries = 0,
        numNoDelayRetries  = 0,
        numMinDelayRetries = 0,
        backoffFunction    = "linear"
      },
      disableSubscriptionOverrides = false,
    }
  })

  # Resource policy for AWS service
  additional_resource_policies = [] # Defautl is [], List of custom resource polciy; [data.aws_iam_policy_document.<name>.json]
  sns_permission_configuration = {  # Defautl is {}
    api_gateway_on_my_account = {
      pricipal = "apigateway.amazonaws.com"
    }
    api_gateway_from_another_account = {
      pricipal       = "apigateway.amazonaws.com"
      source_arn     = "arn:aws:execute-api:ap-southeast-1:557291115693:q6pwa6wgr6/*/*/"
      source_account = "557291115693"
    }
  }

  subscription_configurations = {
    sqs_from_my_account = {
      protocol = "sqs"
      arn      = "arn:aws:sqs:ap-southeast-1:557291035693:manual-sub"
    }
    sqs_from_my_internal_account = {
      protocol = "sqs"
      arn      = "arn:aws:sqs:ap-southeast-1:562563527952:manual-sub"
    }
    ssss = {
      protocol = "email"
    }
  }

  # KMS
  is_enable_encryption = true # Default is true
  is_create_kms        = true # Default is true
  exist_kms_key_arn    = ""   # Default is "", require when is_create_kms is false

  # Message order
  is_fifo_topic                  = false # Default is false
  is_content_based_deduplication = false # Default is false, can change when is_fifo_topic is true

  tags = var.generics_info["custom_tags"]
}

```

- The above subscription will create with follow configuration

```terraform
local.subscription = {
    "protocol" = "https"
  "connect_to_custom_httpss" = {
    "endpoint" = "https://www.google.com"
  }
  "email_0" = {
    "delivery_policy" = jsonencode(var.override_topic_delivery_policy)
    "protocol" = "email"
    "endpoint" = "sedthawut.home@gmail.com"
    "filter_policy" = jsonencode(var.dev_filter_polciy)
    "topic" = "email"
  }
  "email_1" = {
    "delivery_policy" = jsonencode(var.override_topic_delivery_policy)
    "protocol" = "email"
    "endpoint" = "m.s@oozou.com"
    "filter_policy" = jsonencode(var.dev_filter_polciy)
    "topic" = "email"
  }
  "email_2" = {
    "delivery_policy" = jsonencode(var.override_topic_delivery_policy)
    "protocol" = "email"
    "endpoint" = "art.r@oozou.com"
    "filter_policy" = jsonencode(var.dev_filter_polciy)
    "topic" = "email"
  }
  "email_admin_3" = {
    "protocol" = "email"
    "endpoint" = "sedthawut.organize@gmail.com"
    "filter_policy" = jsonencode(var.admin_filter_polciy)
    "topic" = "email_admin"
  }
  "email_admin_4" = {
    "protocol" = "email"
    "endpoint" = "big@oozou.com"
    "filter_policy" = jsonencode(var.admin_filter_polciy)
    "topic" = "email_admin"
  }
}
```
