output "sns_topic_arn" {
  description = "ARN of SNS topic"
  value       = aws_sns_topic.this.arn
}

output "sns_topic_name" {
  description = "NAME of SNS topic"
  value       = aws_sns_topic.this.name
}

output "sns_topic_id" {
  description = "ID of SNS topic"
  value       = aws_sns_topic.this.id
}

output "sns_topic_owner" {
  description = "OWNER of SNS topic"
  value       = aws_sns_topic.this.owner
}
