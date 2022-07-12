data "aws_caller_identity" "default" {}
data "aws_region" "default" {}

locals {
  kms_alias = "${var.base_name}-${var.use_case}-sns-kms-key"
  kms_name  = "${var.base_name}-${var.use_case}-sns-kms-key-${random_string.random_suffix.result}"

  subscriptions = {
    for id, email_id in var.email_ids :
    "Subscription${id}" => {
      "Type" : "AWS::SNS::Subscription",
      "Properties" : {
        "TopicArn" : aws_sns_topic.this.arn,
        "Protocol" : "email",
        "Endpoint" : email_id
      }
    }
  }

  subscription_template = jsonencode({
    "AWSTemplateFormatVersion" : "2010-09-09",
    "Resources" : local.subscriptions
  })

  default_services_allowed_pricipals = [
    "access-analyzer.amazonaws.com",
    "airflow-env.amazonaws.com",
    "airflow.amazonaws.com",
    "apigateway.amazonaws.com",
    "application-autoscaling.amazonaws.com",
    "application-insights.amazonaws.com",
    "athena.amazonaws.com",
    "autoscaling.amazonaws.com",
    "batch.amazonaws.com",
    "budgets.amazonaws.com",
    "chatbot.amazonaws.com",
    "cloudformation.amazonaws.com",
    "cloudfront.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "cloudwatch.amazonaws.com",
    "cloudwatch-crossaccount.amazonaws.com",
    "config-conforms.amazonaws.com",
    "config.amazonaws.com",
    "costalerts.amazonaws.com",
    "delivery.logs.amazonaws.com",
    "dlm.amazonaws.com",
    "dynamodb.amazonaws.com",
    "dynamodb.application-autoscaling.amazonaws.com",
    "ec2.amazonaws.com",
    "ec2.application-autoscaling.amazonaws.com",
    "ecs-tasks.amazonaws.com",
    "ecs.amazonaws.com",
    "ecs.application-autoscaling.amazonaws.com",
    "edgelambda.amazonaws.com",
    "eks-fargate-pods.amazonaws.com",
    "eks-fargate.amazonaws.com",
    "eks-nodegroup.amazonaws.com",
    "eks.amazonaws.com",
    "elasticache.amazonaws.com",
    "elasticfilesystem.amazonaws.com",
    "elasticloadbalancing.amazonaws.com",
    "elasticmapreduce.amazonaws.com",
    "emr-containers.amazonaws.com",
    "es.amazonaws.com",
    "events.amazonaws.com",
    "firehose.amazonaws.com",
    "glue.amazonaws.com",
    "guardduty.amazonaws.com",
    "health.amazonaws.com",
    "iam.amazonaws.com",
    "inspector.amazonaws.com",
    "kafka.amazonaws.com",
    "kinesis.amazonaws.com",
    "kinesisanalytics.amazonaws.com",
    "kms.amazonaws.com",
    "lakeformation.amazonaws.com",
    "lambda.amazonaws.com",
    "logger.cloudfront.amazonaws.com",
    "logs.amazonaws.com",
    "macie.amazonaws.com",
    "monitoring.rds.amazonaws.com",
    "network-firewall.amazonaws.com",
    "ops.apigateway.amazonaws.com",
    "organizations.amazonaws.com",
    "personalize.amazonaws.com",
    "rds.amazonaws.com",
    "s3.amazonaws.com",
    "sagemaker.amazonaws.com",
    "securityhub.amazonaws.com",
    "ses.amazonaws.com",
    "sns.amazonaws.com",
    "spotfleet.amazonaws.com",
    "sqs.amazonaws.com",
    "ssm-incidents.amazonaws.com",
    "ssm.amazonaws.com",
    "states.amazonaws.com",
    "xray.amazonaws.com",
  ]

  services_allowed_pricipals = setunion(compact(var.additional_services_allowed_pricipals), local.default_services_allowed_pricipals)
}
