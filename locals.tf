/* -------------------------------------------------------------------------- */
/*                                   Locals                                   */
/* -------------------------------------------------------------------------- */

locals {
  draft_name   = format("%s-%s-%s", var.prefix, var.environment, var.name)
  name         = format("%s%s", local.draft_name, var.is_fifo_topic ? ".fifo" : "")
  this_sns_arn = format("arn:aws:sns:%s:%s:%s", data.aws_region.this.name, data.aws_caller_identity.this.account_id, local.name)

  kms_key_arn = var.is_enable_encryption ? var.is_create_kms ? module.kms[0].key_arn : var.exist_kms_key_arn : null
  kms_key_id  = var.is_enable_encryption ? replace(local.kms_key_arn, "arn:aws:kms:${data.aws_region.this.name}:${data.aws_caller_identity.this.account_id}:key/", "") : null

  only_update_resource_policy_protocols = ["sqs"]
  allow_subscribe_policy                = { for key, value in var.subscription_configurations : key => value if contains(local.only_update_resource_policy_protocols, value.protocol) }

  email_parsing      = { for key, value in var.subscription_configurations : key => value if contains(["email", "email-json"], value.protocol) }
  email_subscription = { for idx, value in flatten([for topic, config in local.email_parsing : [for address in config.addresses : merge({ "endpoint" = address, "topic" = topic }, { for key, value in config : key => value if key != "addresses" })]]) : format("%s_%s", value.topic, idx) => value }
  # Now we merge new map (email_subscription) with another subscription_configurations that not contains in var.only_update_resource_policy_protocols and ["email", "email-json"]
  subscription = merge(local.email_subscription, { for key, value in var.subscription_configurations : key => value if !contains(concat(local.only_update_resource_policy_protocols, ["email", "email-json"]), value.protocol) })

  deliver_policy = var.override_topic_delivery_policy == "" ? jsonencode(var.default_deliver_policy) : var.override_topic_delivery_policy
  raise_exist_kms_require     = var.is_enable_encryption && var.is_create_kms == false && var.exist_kms_key_arn == "" ? file("var.exist_kms_key_arn is required when var.is_enable_encryption == true and is_create_kms == false") : "pass"
  raise_fifo_condition_failed = var.is_fifo_topic == false && var.is_content_based_deduplication ? file("var.is_content_based_deduplication can be true only when var.raise_fifo_condition_failed is false") : "pass"

  tags = merge(
    {
      "Environment" = var.environment,
      "Terraform"   = "true"
    },
    var.tags
  )
}
