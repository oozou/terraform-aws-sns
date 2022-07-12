variable "base_name" {
  description = "Base name for resource creation"
  type        = string
}

variable "use_case" {
  description = "Used for naming the SNS Resource, use case for which notification is to be sent. E.g. This module can be used for RDS notifications, CodePipeline stage alerts, Fargate alerts, etc."
  type        = string
}

variable "email_ids" {
  description = "List of email ids where alerts are to be published"
  type        = list(string)
  default     = []
}

variable "additional_services_allowed_pricipals" {
  description = "List of additional Service principals that're allowed to action on SNS"
  type        = list(string)
  default     = []
}

variable "custom_tags" {
  description = "Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys"
  type        = map(any)
  default     = {}
}
