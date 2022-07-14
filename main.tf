# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic
# TODO Test with restrict permission with lambda
/* -------------------------------------------------------------------------- */
/*                                   Locals                                   */
/* -------------------------------------------------------------------------- */
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  _name        = format("%s-%s-%s", var.prefix, var.environment, var.name)
  name         = format("%s%s", local._name, var.is_fifo_topic ? ".fifo" : "")
  this_sns_arn = format("arn:aws:sns:%s:%s:%s", data.aws_region.current.name, data.aws_caller_identity.current.account_id, local.name)

  kms_key_arn = var.is_enable_encryption ? var.is_create_kms ? module.kms[0].key_arn : var.exist_kms_key_arn : null
  kms_key_id  = var.is_enable_encryption ? replace(local.kms_key_arn, "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/", "") : null

  sqs_allow_subscribe_policy = { for key, value in var.subscription_configurations : key => value if value.protocol == "sqs" }

  deliver_policy = var.override_topic_deliver_policy == "" ? jsonencode(var.default_deliver_policy) : var.override_topic_deliver_policy

  tags = merge(
    {
      "Environment" = var.environment,
      "Terraform"   = "true"
    },
    var.tags
  )
}

locals {
  raise_exist_kms_require     = var.is_enable_encryption && var.is_create_kms == false && var.exist_kms_key_arn == "" ? file("var.exist_kms_key_arn is required when var.is_enable_encryption == true and is_create_kms == false") : "pass"
  raise_fifo_condition_failed = var.is_fifo_topic == false && var.is_content_based_deduplication ? file("var.is_content_based_deduplication can be true only when var.raise_fifo_condition_failed is false") : "pass"
}

/* -------------------------------------------------------------------------- */
/*                                   AWS KMS                                  */
/* -------------------------------------------------------------------------- */
module "kms" {
  count = var.is_enable_encryption && var.is_create_kms ? 1 : 0

  source = "git@github.com:oozou/terraform-aws-kms-key.git?ref=v1.0.0"

  prefix      = var.prefix
  environment = var.environment
  name        = var.name

  key_type             = "service"
  description          = format("Used to encrypt data in sns %s", local.name)
  append_random_suffix = true

  service_key_info = {
    caller_account_ids = [data.aws_caller_identity.current.account_id]
    aws_service_names  = [format("sns.%s.amazonaws.com", data.aws_region.current.name)]
  }

  additional_policies = var.additional_kms_key_policies

  tags = local.tags
}

/* -------------------------------------------------------------------------- */
/*                                  IAM Role                                  */
/* -------------------------------------------------------------------------- */
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    sid    = "AllowAWSToAssumeRole"
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudformation.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "role_policy" {
  statement {
    sid    = "AllowCloudFormation"
    effect = "Allow"
    actions = [
      "sns:Subscribe",
      "sns:Unsubscribe"
    ]
    resources = [local.this_sns_arn]
  }
}

resource "aws_iam_role" "this" {
  name               = format("%s-role", replace(local.name, ",", "-"))
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = merge(local.tags, { "Name" : format("%s-role", replace(local.name, ",", "-")) })
}

resource "aws_iam_role_policy" "sns_subscription" {
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.role_policy.json
}

/* -------------------------------------------------------------------------- */
/*                                Subscription                                */
/* -------------------------------------------------------------------------- */
# SNS | SQS = aws_sns_topic_subscription in the same region as SNS
# Account A SNS, Account B SQS = aws_sns_topic_subscription must be the same provider as SQS
# If SNS and SQS queue are in different AWS accounts and different AWS regions,
# the subscription needs to be initiated from the account with the SQS queue but in the region of the SNS topic.
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription#attributes-reference
## TODO DO validation for this later (next version)
/* ----------------------------------- SQS ---------------------------------- */
data "aws_iam_policy_document" "sqs_allow_subscribe_policy" {
  dynamic "statement" {
    for_each = local.sqs_allow_subscribe_policy

    content {
      sid = format("AllowToSubsribe-%s", replace(statement.key, "_", "-"))

      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      effect = "Allow"
      actions = [
        "SNS:Subscribe",
        "SNS:Receive",
      ]
      resources = [local.this_sns_arn]

      condition {
        test     = "StringLike"
        variable = "SNS:Endpoint"
        values = [
          lookup(statement.value, "arn", null)
        ]
      }
    }
  }
}

# ANCHOR May be we have to used this one outside module ??
# resource "aws_sns_topic_subscription" "sns_topic" {
#   for_each = var.sqs_allow_subscribe_policy
#   iterator = subscription

#   topic_arn = local.this_sns_arn
#   protocol  = lookup(subscription.value, "protocol", null)
#   endpoint  = lookup(subscription.value, "arn", null)
#   provider  = lookup(subscription.value, "provider", null)
# }

/* -------------------------------------------------------------------------- */
/*                               Resource Policy                              */
/* -------------------------------------------------------------------------- */
data "aws_iam_policy_document" "additional_resource_policy" {
  dynamic "statement" {
    for_each = var.sns_permission_configuration

    content {
      sid    = format("AllowPublishFromAWSService-%s", replace(statement.key, "_", "-"))
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = [lookup(statement.value, "pricipal", null)]
      }

      actions   = ["SNS:Publish"]
      resources = [local.this_sns_arn]

      condition {
        test     = "StringEquals"
        variable = "AWS:SourceOwner"
        values   = [lookup(statement.value, "source_account", data.aws_caller_identity.current.account_id)]
      }

      dynamic "condition" {
        for_each = lookup(statement.value, "source_arn", null) == null ? [] : [true]

        content {
          test     = "ArnLike"
          variable = "aws:SourceArn"
          values   = [lookup(statement.value, "source_arn", null)]
        }
      }
    }
  }
}

data "aws_iam_policy_document" "owner_policy" {
  statement {
    sid    = "DefaultStatement"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish"
    ]
    resources = [local.this_sns_arn]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }
  }
}

data "aws_iam_policy_document" "this" {
  source_policy_documents = [
    data.aws_iam_policy_document.owner_policy.json,
    data.aws_iam_policy_document.additional_resource_policy.json,
    data.aws_iam_policy_document.sqs_allow_subscribe_policy.json
  ]
  override_policy_documents = var.additional_resource_policies
}

/* -------------------------------------------------------------------------- */
/*                                  SNS Topic                                 */
/* -------------------------------------------------------------------------- */
resource "aws_sns_topic" "this" {
  name                        = local.name
  display_name                = var.display_name == "" ? local.name : var.display_name
  policy                      = data.aws_iam_policy_document.this.json
  kms_master_key_id           = local.kms_key_id
  delivery_policy             = local.deliver_policy
  fifo_topic                  = var.is_fifo_topic
  content_based_deduplication = var.is_content_based_deduplication

  application_success_feedback_role_arn    = var.application_success_feedback_role_arn
  application_success_feedback_sample_rate = var.application_success_feedback_sample_rate
  application_failure_feedback_role_arn    = var.application_failure_feedback_role_arn
  http_success_feedback_role_arn           = var.http_success_feedback_role_arn
  http_success_feedback_sample_rate        = var.http_success_feedback_sample_rate
  http_failure_feedback_role_arn           = var.http_failure_feedback_role_arn
  lambda_success_feedback_role_arn         = var.lambda_success_feedback_role_arn
  lambda_success_feedback_sample_rate      = var.lambda_success_feedback_sample_rate
  lambda_failure_feedback_role_arn         = var.lambda_failure_feedback_role_arn
  sqs_success_feedback_role_arn            = var.sqs_success_feedback_role_arn
  sqs_success_feedback_sample_rate         = var.sqs_success_feedback_sample_rate
  sqs_failure_feedback_role_arn            = var.sqs_failure_feedback_role_arn

  tags = merge(local.tags, { "Name" = local.name })
}
