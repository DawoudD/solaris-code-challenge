# --- Lambda execution role ---
# Trust policy allows the Lambda service to assume this role.
resource "aws_iam_role" "lambda_exec" {
  name = "${var.name_prefix}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Required for any VPC-attached Lambda — grants permission to create and
# manage the ENIs needed to place the function inside the private subnets.
resource "aws_iam_role_policy_attachment" "vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Grants CloudWatch Logs write access for standard Lambda logging.
resource "aws_iam_role_policy_attachment" "basic_exec" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Grants read access to exactly the one Secrets Manager secret holding
# the RDS master password — needed because manage_master_user_password
# stores the password there instead of exposing it as a plain value.
resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.name_prefix}-lambda-secrets-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = var.db_secret_arn
      }
    ]
  })
}

# --- Lambda function ---
# VPC-attached (private compute subnets) so it can reach RDS internally,
# while still being invoked externally via the API Gateway integration below.
resource "aws_lambda_function" "api" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_exec.arn
  runtime       = var.runtime
  handler       = var.handler
  timeout       = var.timeout
  filename      = var.filename
  # filename alone doesn't trigger a redeploy when the value is a fixed
  # string across builds (as it is here — the pipeline always writes to
  # "lambda.zip"). Hashing the zip's actual contents ensures Terraform
  # detects and uploads code changes even though the filename never changes.
  source_code_hash = filebase64sha256(var.filename)

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  }

  environment {
    variables = var.environment_variables
  }

  tags = {
    Name = "${var.name_prefix}-lambda"
  }
}

# --- API Gateway (HTTP API) ---
# Public-facing entry point, lives outside the VPC by default.
resource "aws_apigatewayv2_api" "this" {
  name          = var.api_name
  protocol_type = "HTTP"
}

# Connects the API to the Lambda function.
resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
}

# Catch-all route — forwards any method/path to the Lambda integration.
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = true
}

# Explicitly grants API Gateway permission to invoke the Lambda function —
# required even though the integration is already wired up above.
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
