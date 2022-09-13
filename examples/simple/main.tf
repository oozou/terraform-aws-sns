locals {
  daft_name = format("%s-%s-%s", var.prefix, var.environment, var.name)
}

module "sns" {
  source = "../../"

  prefix       = var.prefix
  environment  = var.environment
  name         = format("%s%s", local.daft_name, false ? ".fifo" : "")
  display_name = "God of Gor Don" # Default is "", name appear with message; no affect to resource arn

  # Send message to
  subscription_configurations = {
    email = {
      protocol  = "email"
      addresses = ["nai_a@hotmail.com", "nai_b@hotmail.com", "nai_c@hotmail.com"]
    }
    connect_to_custom_httpss = {
      protocol = "https"
      endpoint = "https://www.google.com"
    }
  }

  tags = var.custom_tags
}
