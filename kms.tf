/* -------------------------------------------------------------------------- */
/*                                   AWS KMS                                  */
/* -------------------------------------------------------------------------- */
module "kms" {
  count = var.is_enable_encryption && var.is_create_kms ? 1 : 0

  source  = "oozou/kms-key/aws"
  version = "1.0.0"

  prefix      = var.prefix
  environment = var.environment
  name        = var.name

  key_type             = "service"
  description          = format("Used to encrypt data in sns %s", local.name)
  append_random_suffix = true

  service_key_info = {
    caller_account_ids = [data.aws_caller_identity.this.account_id]
    aws_service_names  = [format("sns.%s.amazonaws.com", data.aws_region.this.name)]
  }

  additional_policies = var.additional_kms_key_policies

  tags = local.tags
}
