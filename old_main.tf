# variable "use_case" {
#   description = "Used for naming the SNS Resource, use case for which notification is to be sent. E.g. This module can be used for RDS notifications, CodePipeline stage alerts, Fargate alerts, etc."
#   type        = string
# }

# variable "email_ids" {
#   description = "List of email ids where alerts are to be published"
#   type        = list(string)
#   default     = []
# }

# locals {
#   subscriptions = {
#     for id, email_id in var.email_ids :
#     "Subscription${id}" => {
#       "Type" : "AWS::SNS::Subscription",
#       "Properties" : {
#         "TopicArn" : aws_sns_topic.this.arn,
#         "Protocol" : "email",
#         "Endpoint" : email_id
#       }
#     }
#   }

#   subscription_template = jsonencode({
#     "AWSTemplateFormatVersion" : "2010-09-09",
#     "Resources" : local.subscriptions
#   })
# }

#  aws_sns_topic.this

# # Cloudformation stack complains of Invalid IAM role because of IAM eventual consistency to propagate to other services. Normally retry logic has been implicitly added to many aws resources in terraform provider like ECR but cloudformation_stack is still missing that.
# # Normally 1 minute should be good enough. Ref: https://github.com/terraform-providers/terraform-provider-aws/pull/1165#issue-130759721
# resource "time_sleep" "wait_1_minute" {
#   depends_on = [aws_iam_role.sns_subscription]

#   create_duration = "1m"
# }

# # aws_sns_topic_subscription does not support email protocol because the endpoint needs to be authorized and does not generate an ARN until the target email address has been validated. This breaks the Terraform model and as a result are not currently supported.
# # The cloudformation stack below creates the sns subscription along with triggering the subscription emails. User will still need to manually confirm the subscription link in the emails though.
# resource "aws_cloudformation_stack" "sns_subscriptions" {
#   name          = "${var.base_name}-${var.use_case}"
#   template_body = local.subscription_template

#   iam_role_arn = aws_iam_role.sns_subscription.arn

#   count = signum(length(var.email_ids))

#   tags = merge({
#     Name = "${var.base_name}-${var.use_case}-sns-subscriptions"
#   }, var.custom_tags)

#   depends_on = [time_sleep.wait_1_minute]
# }
