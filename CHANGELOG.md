## v1.0.x

### v1.0.0

- What's Changed
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
    - Add FIFO and deduplication function to be toggle
