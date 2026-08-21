variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "name_prefix" {
  description = "Prefix used to name and tag all resources"
  type        = string
  default     = "solaris"
}

variable "availability_zones" {
  description = "AZs to spread subnets across"
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "compute_subnet_cidrs" {
  description = "CIDR blocks for the private compute (Lambda) subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "data_subnet_cidrs" {
  description = "CIDR blocks for the private data (RDS) subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# Postgres confirmed as the RDS engine — default port 5432.
variable "db_port" {
  description = "Port the RDS instance listens on"
  type        = number
  default     = 5432
}

variable "db_engine_version" {
  description = "Postgres engine version"
  type        = string
  default     = "16"
}

# db.t3.medium per the brief's "standard compute capacity" requirement.
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the RDS instance, in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Name of the initial database created on the instance"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "appadmin"
}

variable "lambda_runtime" {
  description = "Lambda runtime for the Node.js API"
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_handler" {
  description = "Lambda function handler"
  type        = string
  default     = "index.handler"
}

# No default — the API code doesn't exist yet. Will be supplied once
# the CI/CD pipeline builds and packages the Lambda deployment artifact.
variable "lambda_filename" {
  description = "Path to the Lambda deployment package (zip file)"
  type        = string
}

variable "stage_name" {
  description = "API Gateway deployment stage name"
  type        = string
  default     = "$default"
}
