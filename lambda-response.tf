resource "aws_sns_topic" "security_alerts" {
  name = "security-lab-alerts"

  tags = {
    Name = "security-lab-alerts"
  }
}

resource "aws_iam_role" "lambda_response_role" {
  name = "security-lab-lambda-response-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "security-lab-lambda-response-role"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_response_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_sns_publish" {
  name = "security-lab-lambda-sns-publish"
  role = aws_iam_role.lambda_response_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.security_alerts.arn
    }]
  })
}

data "archive_file" "guardduty_response" {
  type        = "zip"
  source_file = "${path.module}/lambda_functions/guardduty_response/handler.py"
  output_path = "${path.module}/lambda_functions/guardduty_response.zip"
}

resource "aws_lambda_function" "guardduty_response" {
  function_name    = "security-lab-guardduty-response"
  role              = aws_iam_role.lambda_response_role.arn
  handler           = "handler.lambda_handler"
  runtime           = "python3.12"
  filename          = data.archive_file.guardduty_response.output_path
  source_code_hash  = data.archive_file.guardduty_response.output_base64sha256
  timeout           = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn
    }
  }

  tags = {
    Name = "security-lab-guardduty-response"
  }
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "security-lab-guardduty-findings"
  description = "Route GuardDuty findings to Lambda for automated response"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "guardduty-response-lambda"
  arn       = aws_lambda_function.guardduty_response.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guardduty_response.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
}
