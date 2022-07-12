output "topic_arn" {
  description = "ARN of sns topic created"
  value       = aws_sns_topic.this.arn
}
