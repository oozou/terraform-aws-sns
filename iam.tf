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
data "aws_iam_policy_document" "allow_subscribe_policy" {
  dynamic "statement" {
    for_each = local.allow_subscribe_policy

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
          lookup(statement.value, "endpoint", null)
        ]
      }
    }
  }
}

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
        data.aws_caller_identity.this.account_id,
      ]
    }
  }
}

data "aws_iam_policy_document" "this" {
  source_policy_documents = [
    data.aws_iam_policy_document.owner_policy.json,
    data.aws_iam_policy_document.additional_resource_policy.json,
    data.aws_iam_policy_document.allow_subscribe_policy.json
  ]
  override_policy_documents = var.additional_resource_policies
}
