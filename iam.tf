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
