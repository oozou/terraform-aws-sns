# Change Log

All notable changes to this module will be documented in this file.

## [1.0.1] - 2022-09-16

### Fixed

- `var.sns_permission_configuration` resource policy condition bug

## [1.0.0] - 2022-02-27

### Added

- Remove resource `aws_kms_key.service_key` and `aws_kms_alias.service_key` 
- Add KMS module with default service sns
    - Remove `data.aws_iam_policy_document.kms_key_policy_via_service`
        - Sum statement have create by KMS module
        - There's removed statement `Allow_CloudWatch_for_CMK` and `Allow_EventBridge_for_CMK`
        - If you still need it, just use a `var.additional_kms_key_policies`
- KMS Logic
    | is_enable | is_create | kms_arn   | Encryption         | KMS Creation       | KMS Usage          | Error                 |
    |-----------|-----------|-----------|--------------------|--------------------|--------------------|-----------------------|
    | `false`   | `false`   | ""        |                    |                    |                    |                       |
    | `false`   | `false`   | "\<arn\>" |                    |                    |                    |                       |
    | `false`   | `true`    | ""        |                    |                    |                    |                       |
    | `false`   | `true`    | "\<arn\>" |                    |                    |                    |                       |
    | `true`    | `false`   | ""        |                    |                    |                    | :o:                   |
    | `true`    | `false`   | "\<arn\>" | :heavy_check_mark: |                    | :heavy_check_mark: |                       |
    | `true`    | `true`    | ""        | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |                       |
    | `true`    | `true`    | "\<arn\>" | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | kms_arn will not used |
- Add FIFO and de-duplication function to be toggle
- Add default deliver topic policy and ability to override it
- Add resource policy that can restrict to source arn, source account id. Moreover the ability to use custom resource policy as overriding
- Add auto create subscription policies for SQS service to allow subscription to SNS
    - For now `no` subscription (resource) are create inside this module (See Enhancement)


### Enhancement
    - Make more generic for policy creation (use existing policies) [Over Engineer]
    - Add automatic subscription policy creation to the SNS service
        - There is no way to create the resource 'aws sns topic subscription' within the module, as AWS provider requirements for SQS and SNS depend on the region and AWS account ID.
    - Need test for service expansion (sms, lambda, firehose, and application, ...) [See available protocol.](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription#protocol)
        - This version has only been tested with sqs, http(s), email, and email-json services.
        - If new protocol cannot create resource `aws_sns_topic_subscription` within this module, you can only update policy to permit subscribe from that protocol within `local.only_update_resource_policy_protocols`
    - Needs Improvement: When utilizing with SQS, you must still apply twice
