output "api_endpoint" {
  description = "Public invoke URL of the API Gateway stage"
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.api.arn
}
