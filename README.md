# terraform-aws-sns

## Usage

```terraform
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  _name = format("%s-%s-%s", var.generics_info["prefix"], var.generics_info["environment"], var.generics_info["name"])
  name  = format("%s%s", local._name, false ? ".fifo" : "")

  this_sns_arn = format("arn:aws:sns:%s:%s:%s", data.aws_region.current.name, data.aws_caller_identity.current.account_id, local.name)
  sqs_arn      = format("arn:aws:sqs:%s:%s:%s", data.aws_region.current.name, data.aws_caller_identity.current.account_id, local.name)
}

module "sns" {
  source = "git@github.com:oozou/terraform-aws-sns.git?ref=<version>"

  prefix       = var.generics_info["prefix"]
  environment  = var.generics_info["environment"]
  name         = var.generics_info["name"]
  display_name = "God of Gor Don" # Default is "", name appear with message; no affect to resource arn

  # https://docs.aws.amazon.com/sns/latest/dg/sns-message-delivery-retries.html
  override_topic_delivery_policy = jsonencode({ # Default is "", use to override defualt topic deliver policy
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

  # Send message to
  subscription_configurations = {
    sqs_from_my_account = {
      protocol = "sqs"
      endpoint = local.sqs_arn
    }
    email = {
      protocol        = "email"
      addresses       = ["sedthawut.home@gmail.com", "m.s@oozou.com", "art.r@oozou.com"]
      delivery_policy = jsonencode(var.override_topic_delivery_policy) # To override the topic delivery policy
      filter_policy   = jsonencode(var.dev_filter_polciy)              # To set filter policy for this subscription
    }
    email_admin = {
      protocol      = "email"
      addresses     = ["sedthawut.org@gmail.com", "big@oozou.com"]
      filter_policy = jsonencode(var.admin_filter_polciy)
    }
    connect_to_custom_httpss = {
      protocol = "https"
      endpoint = "https://www.google.com"
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

data "aws_iam_policy_document" "sqs_queue_policy" {
  statement {
    sid    = "AllowSendMessageFrom"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "SQS:SendMessage",
    ]
    resources = [
      local.sqs_arn # Artifically created by format() string
    ]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.this_sns_arn]
    }
  }
}

resource "aws_sqs_queue" "sqs" {
  name                      = local.name
  policy                    = data.aws_iam_policy_document.sqs_queue_policy.json
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10

  tags = var.generics_info["custom_tags"]
}

resource "aws_sns_topic_subscription" "sns_topic" {
  topic_arn = local.this_sns_arn
  protocol  = "sqs"
  endpoint  = local.sqs_arn
}

```

- The above subscription will create with follow configuration

```terraform
local.subscription = {
  "connect_to_custom_httpss" = {
    "protocol" = "https"
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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name                                                                      | Version  |
|---------------------------------------------------------------------------|----------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | >= 4.0   |

## Providers

| Name                                              | Version |
|---------------------------------------------------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.22.0  |

## Modules

| Name                                          | Source                                         | Version |
|-----------------------------------------------|------------------------------------------------|---------|
| <a name="module_kms"></a> [kms](#module\_kms) | git@github.com:oozou/terraform-aws-kms-key.git | v1.0.0  |

## Resources

| Name                                                                                                                                                     | Type        |
|----------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                | resource    |
| [aws_iam_role_policy.sns_subscription](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy)                      | resource    |
| [aws_sns_topic.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic)                                              | resource    |
| [aws_sns_topic_subscription.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription)                    | resource    |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                            | data source |
| [aws_iam_policy_document.additional_resource_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.allow_subscribe_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)     | data source |
| [aws_iam_policy_document.assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)         | data source |
| [aws_iam_policy_document.owner_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)               | data source |
| [aws_iam_policy_document.role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)                | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)                       | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                              | data source |

## Inputs

| Name                                                                                                                                                               | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Type           | Default                                                                                                                                                                                                                                                                                                                                                                | Required |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------:|
| <a name="input_additional_kms_key_policies"></a> [additional\_kms\_key\_policies](#input\_additional\_kms\_key\_policies)                                          | Additional IAM policies block, input as data source. Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document                                                                                                                                                                                                                                                                                                                                                                                                            | `list(string)` | `[]`                                                                                                                                                                                                                                                                                                                                                                   |    no    |
| <a name="input_additional_resource_policies"></a> [additional\_resource\_policies](#input\_additional\_resource\_policies)                                         | Additional IAM policies block, input as data source. Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document                                                                                                                                                                                                                                                                                                                                                                                                            | `list(string)` | `[]`                                                                                                                                                                                                                                                                                                                                                                   |    no    |
| <a name="input_application_failure_feedback_role_arn"></a> [application\_failure\_feedback\_role\_arn](#input\_application\_failure\_feedback\_role\_arn)          | IAM role for failure feedback                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `string`       | `null`                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_application_success_feedback_role_arn"></a> [application\_success\_feedback\_role\_arn](#input\_application\_success\_feedback\_role\_arn)          | The IAM role permitted to receive success feedback for this topic                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | `string`       | `null`                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_application_success_feedback_sample_rate"></a> [application\_success\_feedback\_sample\_rate](#input\_application\_success\_feedback\_sample\_rate) | Percentage of success to sample                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | `string`       | `null`                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_default_deliver_policy"></a> [default\_deliver\_policy](#input\_default\_deliver\_policy)                                                           | The default deliver policy for SNS                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | `any`          | <pre>{<br>  "http": {<br>    "defaultHealthyRetryPolicy": {<br>      "backoffFunction": "linear",<br>      "maxDelayTarget": 20,<br>      "minDelayTarget": 20,<br>      "numMaxDelayRetries": 0,<br>      "numMinDelayRetries": 0,<br>      "numNoDelayRetries": 0,<br>      "numRetries": 3<br>    },<br>    "disableSubscriptionOverrides": false<br>  }<br>}</pre> |    no    |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name)                                                                                           | The display name for the SNS topic                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | `string`       | `""`                                                                                                                                                                                                                                                                                                                                                                   |    no    |
| <a name="input_environment"></a> [environment](#input\_environment)                                                                                                | Environment Variable used as a prefix                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `string`       | n/a                                                                                                                                                                                                                                                                                                                                                                    |   yes    |
| <a name="input_exist_kms_key_arn"></a> [exist\_kms\_key\_arn](#input\_exist\_kms\_key\_arn)                                                                        | The Amazon Resource Name (ARN) of the key.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | `string`       | `""`                                                                                                                                                                                                                                                                                                                                                                   |    no    |
| <a name="input_http_failure_feedback_role_arn"></a> [http\_failure\_feedback\_role\_arn](#input\_http\_failure\_feedback\_role\_arn)                               | IAM role for failure feedback                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `string`       | `null`                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_http_success_feedback_role_arn"></a> [http\_success\_feedback\_role\_arn](#input\_http\_success\_feedback\_role\_arn)                               | The IAM role permitted to receive success feedback for this topic                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | `string`       | `null`                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_http_success_feedback_sample_rate"></a> [http\_success\_feedback\_sample\_rate](#input\_http\_success\_feedback\_sample\_rate)                      | Percentage of success to sample                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | `string`       | `null`                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_is_content_based_deduplication"></a> [is\_content\_based\_deduplication](#input\_is\_content\_based\_deduplication)                                 | Boolean indicating whether or not to enable content-based deduplication for FIFO topics.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | `bool`         | `false`                                                                                                                                                                                                                                                                                                                                                                |    no    |
| <a name="input_is_create_kms"></a> [is\_create\_kms](#input\_is\_create\_kms)                                                                                      | Specifies whether kms will be created by this module or not                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | `bool`         | `true`                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_is_enable_encryption"></a> [is\_enable\_encryption](#input\_is\_enable\_encryption)                                                                 | Specifies whether the DB instance is encrypted                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | `bool`         | `true`                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_is_fifo_topic"></a> [is\_fifo\_topic](#input\_is\_fifo\_topic)                                                                                      | Boolean indicating whether or not to create a FIFO (first-in-first-out) topic                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `bool`         | `false`                                                                                                                                                                                                                                                                                                                                                                |    no    |
| <a name="input_lambda_failure_feedback_role_arn"></a> [lambda\_failure\_feedback\_role\_arn](#input\_lambda\_failure\_feedback\_role\_arn)                         | IAM role for failure feedback                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `string`       | `null`                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_lambda_success_feedback_role_arn"></a> [lambda\_success\_feedback\_role\_arn](#input\_lambda\_success\_feedback\_role\_arn)                         | The IAM role permitted to receive success feedback for this topic                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | `string`       | `null`                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_lambda_success_feedback_sample_rate"></a> [lambda\_success\_feedback\_sample\_rate](#input\_lambda\_success\_feedback\_sample\_rate)                | Percentage of success to sample                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | `string`       | `null`                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_name"></a> [name](#input\_name)                                                                                                                     | Name of resource                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | `string`       | n/a                                                                                                                                                                                                                                                                                                                                                                    |   yes    |
| <a name="input_override_topic_delivery_policy"></a> [override\_topic\_delivery\_policy](#input\_override\_topic\_delivery\_policy)                                 | Overide the default deliver policy with jsonencode(map)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | `string`       | `""`                                                                                                                                                                                                                                                                                                                                                                   |    no    |
| <a name="input_prefix"></a> [prefix](#input\_prefix)                                                                                                               | The prefix name of customer to be displayed in AWS console and resource                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | `string`       | n/a                                                                                                                                                                                                                                                                                                                                                                    |   yes    |
| <a name="input_sns_permission_configuration"></a> [sns\_permission\_configuration](#input\_sns\_permission\_configuration)                                         | Enable thing to Publish to this service<br>  principal  - (Required) The principal who is getting this permission e.g., s3.amazonaws.com, an AWS account ID, or any valid AWS service principal such as events.amazonaws.com or sns.amazonaws.com.<br>  source\_arn - (Optional) When the principal is an AWS service, the ARN of the specific resource within that service to grant permission to. Without this, any resource from<br>  source\_account - (Optional) This parameter is used for S3 and SES. The AWS account ID (without a hyphen) of the source owner. | `any`          | `{}`                                                                                                                                                                                                                                                                                                                                                                   |    no    |
| <a name="input_sqs_failure_feedback_role_arn"></a> [sqs\_failure\_feedback\_role\_arn](#input\_sqs\_failure\_feedback\_role\_arn)                                  | IAM role for failure feedback                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | `string`       | `null`                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_sqs_success_feedback_role_arn"></a> [sqs\_success\_feedback\_role\_arn](#input\_sqs\_success\_feedback\_role\_arn)                                  | The IAM role permitted to receive success feedback for this topic                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | `string`       | `null`                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_sqs_success_feedback_sample_rate"></a> [sqs\_success\_feedback\_sample\_rate](#input\_sqs\_success\_feedback\_sample\_rate)                         | Percentage of success to sample                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | `string`       | `null`                                                                                                                                                                                                                                                                                                                                                                 |    no    |
| <a name="input_subscription_configurations"></a> [subscription\_configurations](#input\_subscription\_configurations)                                              | Subscription infomation                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | `any`          | `{}`                                                                                                                                                                                                                                                                                                                                                                   |    no    |
| <a name="input_tags"></a> [tags](#input\_tags)                                                                                                                     | Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys                                                                                                                                                                                                                                                                                                                                                                                                                                                            | `map(any)`     | `{}`                                                                                                                                                                                                                                                                                                                                                                   |    no    |

## Outputs

| Name                                                                                  | Description        |
|---------------------------------------------------------------------------------------|--------------------|
| <a name="output_sns_topic_arn"></a> [sns\_topic\_arn](#output\_sns\_topic\_arn)       | ARN of SNS topic   |
| <a name="output_sns_topic_id"></a> [sns\_topic\_id](#output\_sns\_topic\_id)          | ID of SNS topic    |
| <a name="output_sns_topic_name"></a> [sns\_topic\_name](#output\_sns\_topic\_name)    | NAME of SNS topic  |
| <a name="output_sns_topic_owner"></a> [sns\_topic\_owner](#output\_sns\_topic\_owner) | OWNER of SNS topic |
<!-- END_TF_DOCS -->
