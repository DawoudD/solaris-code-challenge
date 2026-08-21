variable "name_prefix" {
  description = "Prefix used to name and tag compute resources"
  type        = string
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (e.g. nodejs20.x)"
  type        = string
}

variable "handler" {
  description = "Lambda function handler (e.g. index.handler)"
  type        = string
}

# The API code doesn't exist yet, so the deployment package is left as a
# variable rather than a real artifact. Will be populated once the
# CI/CD pipeline builds and packages the Node.js code.
variable "filename" {
  description = "Path to the Lambda deployment package (zip file)"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables passed to the Lambda function (e.g. DB connection details)"
  type        = map(string)
  default     = {}
}

# Supplied from the networking module's outputs at the call site.
variable "subnet_ids" {
  description = "Private compute subnet IDs the Lambda function will attach to"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs to attach to the Lambda function"
  type        = list(string)
}

# ARN of the Secrets Manager secret holding the RDS master password —
# used to scope the IAM permission granting Lambda read access to it.
variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the RDS master password"
  type        = string
}

variable "api_name" {
  description = "Name of the API Gateway HTTP API"
  type        = string
}

variable "stage_name" {
  description = "Name of the API Gateway deployment stage"
  type        = string
  default     = "$default"
}
