resource "aws_sns_topic_subscription" "this" {
  for_each = local.subscription

  topic_arn              = local.this_sns_arn
  protocol               = lookup(each.value, "protocol", null)
  endpoint               = lookup(each.value, "endpoint", null)
  delivery_policy        = lookup(each.value, "delivery_policy", null)
  redrive_policy         = lookup(each.value, "redrive_policy", null)
  filter_policy          = lookup(each.value, "filter_policy", null)
  subscription_role_arn  = lookup(each.value, "subscription_role_arn", null)
  raw_message_delivery   = lookup(each.value, "raw_message_delivery", null)
  endpoint_auto_confirms = lookup(each.value, "endpoint_auto_confirms", null)
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
