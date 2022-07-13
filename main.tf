# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic
# deliver policy -> https://docs.aws.amazon.com/sns/latest/dg/sns-message-delivery-retries.html
/* -------------------------------------------------------------------------- */
/*                                   Locals                                   */
/* -------------------------------------------------------------------------- */
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name         = format("%s-%s-%s", var.prefix, var.environment, var.name)
  this_sns_arn = "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.name}"

  kms_key_arn = var.is_enable_encryption ? var.is_create_kms ? module.kms[0].key_arn : var.exist_kms_key_arn : null
  kms_key_id  = var.is_enable_encryption ? replace(local.kms_key_arn, "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/", "") : null

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
/*                               Resource Policy                              */
/* -------------------------------------------------------------------------- */
# TODO make override and additional resource policy
data "aws_iam_policy_document" "this" {
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
/*                                  SNS Topic                                 */
/* -------------------------------------------------------------------------- */
resource "aws_sns_topic" "this" {
  name                        = format("%s%s", local.name, var.is_fifo_topic ? ".fifo" : "") # /
  display_name                = var.display_name == "" ? local.name : var.display_name       # /
  policy                      = data.aws_iam_policy_document.this.json                       # /
  kms_master_key_id           = local.kms_key_id                                             # /
  delivery_policy             = var.delivery_policy
  fifo_topic                  = var.is_fifo_topic                  # /
  content_based_deduplication = var.is_content_based_deduplication # /

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

  tags = merge(local.tags, { "Name" = format("%s%s", local.name, var.is_fifo_topic ? ".fifo" : "") }) # /
}
