# terraform-aws-sns

## Usage

```terraform
module "sns" {
  source = "git@github.com:oozou/terraform-aws-sns.git?ref=<version>"

  prefix       = var.generics_info["prefix"]
  environment  = var.generics_info["environment"]
  name         = var.generics_info["name"]
  display_name = "God of Gor Don" # Default is "", name appear with message; no affect to resource arn

  # KMS
  is_enable_encryption = true               # Default is true
  is_create_kms        = true               # Default is true
  exist_kms_key_arn    = module.kms.key_arn # Default is "", require when is_create_kms is false

  # Message order
  is_fifo_topic                  = true  # Default is false
  is_content_based_deduplication = false # Default is false, can change when is_fifo_topic is true
}

```
