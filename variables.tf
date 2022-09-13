/* -------------------------------------------------------------------------- */
/*                                   Generic                                  */
/* -------------------------------------------------------------------------- */
variable "prefix" {
  description = "The prefix name of customer to be displayed in AWS console and resource"
  type        = string
}

variable "environment" {
  description = "Environment Variable used as a prefix"
  type        = string
}

variable "name" {
  description = "Name of resource"
  type        = string
}

variable "display_name" {
  description = "The display name for the SNS topic"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Custom tags which can be passed on to the AWS resources. They should be key value pairs having distinct keys"
  type        = map(any)
  default     = {}
}

/* -------------------------------------------------------------------------- */
/*                                     KMS                                    */
/* -------------------------------------------------------------------------- */
variable "is_enable_encryption" {
  description = "Specifies whether the DB instance is encrypted"
  type        = bool
  default     = true
}

variable "is_create_kms" {
  description = "Specifies whether kms will be created by this module or not"
  type        = bool
  default     = true
}

variable "exist_kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the key."
  type        = string
  default     = ""
}

variable "additional_kms_key_policies" {
  description = "Additional IAM policies block, input as data source. Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document"
  type        = list(string)
  default     = []
}

/* -------------------------------------------------------------------------- */
/*                                     SNS                                    */
/* -------------------------------------------------------------------------- */
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription#attributes-reference
variable "subscription_configurations" {
  description = "Subscription infomation"
  type        = any
  default     = {}
}

variable "default_deliver_policy" {
  description = "The default deliver policy for SNS"
  type        = any
  default = {
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20,
        maxDelayTarget     = 20,
        numRetries         = 3,
        numMaxDelayRetries = 0,
        numNoDelayRetries  = 0,
        numMinDelayRetries = 0,
        backoffFunction    = "linear"
      },
      disableSubscriptionOverrides = false,
    }
  }
}

variable "is_fifo_topic" {
  description = "Boolean indicating whether or not to create a FIFO (first-in-first-out) topic"
  type        = bool
  default     = false
}

variable "is_content_based_deduplication" {
  description = "Boolean indicating whether or not to enable content-based deduplication for FIFO topics."
  type        = bool
  default     = false
}

variable "sns_permission_configuration" {
  description = <<EOF
  Enable thing to Publish to this service
  principal  - (Required) The principal who is getting this permission e.g., s3.amazonaws.com, an AWS account ID, or any valid AWS service principal such as events.amazonaws.com or sns.amazonaws.com.
  source_arn - (Optional) When the principal is an AWS service, the ARN of the specific resource within that service to grant permission to. Without this, any resource from
  source_account - (Optional) This parameter is used for S3 and SES. The AWS account ID (without a hyphen) of the source owner.
  EOF
  type        = any
  default     = {}
}

variable "additional_resource_policies" {
  description = "Additional IAM policies block, input as data source. Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document"
  type        = list(string)
  default     = []
}

variable "override_topic_delivery_policy" {
  description = "Overide the default deliver policy with jsonencode(map)"
  type        = string
  default     = ""
}

variable "application_success_feedback_role_arn" {
  description = "The IAM role permitted to receive success feedback for this topic"
  type        = string
  default     = null
}

variable "application_success_feedback_sample_rate" {
  description = "Percentage of success to sample"
  type        = string
  default     = null
}

variable "application_failure_feedback_role_arn" {
  description = "IAM role for failure feedback"
  type        = string
  default     = null
}

variable "http_success_feedback_role_arn" {
  description = "The IAM role permitted to receive success feedback for this topic"
  type        = string
  default     = null
}

variable "http_success_feedback_sample_rate" {
  description = "Percentage of success to sample"
  type        = string
  default     = null
}

variable "http_failure_feedback_role_arn" {
  description = "IAM role for failure feedback"
  type        = string
  default     = null
}

variable "lambda_success_feedback_role_arn" {
  description = "The IAM role permitted to receive success feedback for this topic"
  type        = string
  default     = null
}

variable "lambda_success_feedback_sample_rate" {
  description = "Percentage of success to sample"
  type        = string
  default     = null
}

variable "lambda_failure_feedback_role_arn" {
  description = "IAM role for failure feedback"
  type        = string
  default     = null
}

variable "sqs_success_feedback_role_arn" {
  description = "The IAM role permitted to receive success feedback for this topic"
  type        = string
  default     = null
}

variable "sqs_success_feedback_sample_rate" {
  description = "Percentage of success to sample"
  type        = string
  default     = null
}

variable "sqs_failure_feedback_role_arn" {
  description = "IAM role for failure feedback"
  type        = string
  default     = null
}
