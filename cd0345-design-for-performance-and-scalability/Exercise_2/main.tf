provider "aws" {
  access_key = "AKIA5BUBN3OZJE5DERZ3"
  secret_key = "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"
  region     = var.aws_region
}

# Lambda function IAM role to create log groups
resource "aws_iam_role" "iam_for_lambda_function" {
  name = "iam_for_lambda_function"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = ["lambda.amazonaws.com"]
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ],
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda_function.name
  policy_arn = aws_iam_policy.lambda_logging.arn

}

resource "aws_cloudwatch_log_group" "udaicty_project_log_group" {
  name              = "/aws/lambda/lambda_for_udacity_project"
  retention_in_days = 14
}

# Create archive for Lambda function
data "archive_file" "python_lambda_package" {
  type        = "zip"
  source_file = "./greet_lambda.py"
  output_path = "greet_lambda.zip"
}

# Resource for Lambda function
resource "aws_lambda_function" "lambda_for_udacity_project" {
  function_name    = "lambda_for_udacity_project"
  filename         = "greet_lambda.zip"
  role             = aws_iam_role.iam_for_lambda_function.arn
  handler          = "greet_lambda.lambda_handler"
  source_code_hash = data.archive_file.python_lambda_package.output_base64sha256
  runtime          = "python3.8"
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.udaicty_project_log_group,
  ]

  environment {
    variables = {
      greeting = "Hello"
    }
  }
}
