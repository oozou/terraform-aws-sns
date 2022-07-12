resource "aws_sns_topic" "this" {
  name              = "${var.base_name}-${var.use_case}"
  kms_master_key_id = aws_kms_key.service_key.arn

  tags = merge({
    Name = "${var.base_name}-${var.use_case}"
  }, var.custom_tags)
}

# Cloudformation stack complains of Invalid IAM role because of IAM eventual consistency to propagate to other services. Normally retry logic has been implicitly added to many aws resources in terraform provider like ECR but cloudformation_stack is still missing that.
# Normally 1 minute should be good enough. Ref: https://github.com/terraform-providers/terraform-provider-aws/pull/1165#issue-130759721
resource "time_sleep" "wait_1_minute" {
  depends_on = [aws_iam_role.sns_subscription]

  create_duration = "1m"
}

# aws_sns_topic_subscription does not support email protocol because the endpoint needs to be authorized and does not generate an ARN until the target email address has been validated. This breaks the Terraform model and as a result are not currently supported.
# The cloudformation stack below creates the sns subscription along with triggering the subscription emails. User will still need to manually confirm the subscription link in the emails though.
resource "aws_cloudformation_stack" "sns_subscriptions" {
  name          = "${var.base_name}-${var.use_case}"
  template_body = local.subscription_template

  iam_role_arn = aws_iam_role.sns_subscription.arn

  count = signum(length(var.email_ids))

  tags = merge({
    Name = "${var.base_name}-${var.use_case}-sns-subscriptions"
  }, var.custom_tags)

  depends_on = [time_sleep.wait_1_minute]
}

resource "aws_sns_topic_policy" "this" {
  arn = aws_sns_topic.this.arn

  policy = data.aws_iam_policy_document.this.json
}

// fetch PowerUser SSO arn
data "aws_iam_roles" "poweruser" {
  name_regex  = "AWSReservedSSO_PowerUser_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/ap-southeast-1/"
}

data "aws_iam_policy_document" "this" {
  statement {
    sid    = "AllowPublishFromAWSService"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = local.services_allowed_pricipals
    }

    actions = [
      "SNS:Publish",
    ]

    resources = [aws_sns_topic.this.arn]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.default.account_id,
      ]
    }
  }

  statement {
    sid    = "AllowActionsForPowerUser"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = concat(tolist([data.aws_caller_identity.default.arn]), tolist(data.aws_iam_roles.poweruser.arns))
    }

    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    resources = [aws_sns_topic.this.arn]
  }
}
