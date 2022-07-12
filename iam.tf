resource "aws_iam_role" "sns_subscription" {
  path = "/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudformation.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = merge({
    Name = "${var.base_name}-${var.use_case}-sns-subscriber"
  }, var.custom_tags)
}

resource "aws_iam_role_policy" "sns_subscription" {
  role = aws_iam_role.sns_subscription.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sns:Subscribe",
        "sns:Unsubscribe"
      ],
      "Resource": "${aws_sns_topic.this.arn}"
    }
  ]
}
POLICY
}
