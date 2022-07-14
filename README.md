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

  # KMS
  is_enable_encryption = true               # Default is true
  is_create_kms        = false              # Default is true
  exist_kms_key_arn    = module.kms.key_arn # Default is "", require when is_create_kms is false

  # Message order
  is_fifo_topic                  = false # Default is false
  is_content_based_deduplication = false # Default is false, can change when is_fifo_topic is true

  tags = var.generics_info["custom_tags"]
}

```
