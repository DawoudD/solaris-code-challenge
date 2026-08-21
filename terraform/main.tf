terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state, required so GitHub Actions runs (ephemeral, no local
  # state between runs) share state with each other and with local runs.
  # NOTE: this bucket must be created manually, once, before the first
  # `terraform init` against this backend — Terraform can't create the
  # bucket it's about to store its own state in. Update the bucket name
  # below to match whatever you actually create.
  backend "s3" {
    bucket = "solaris-code-challenge-tfstate"
    key    = "solaris/terraform.tfstate"
    region = "eu-west-2"
  }
}

provider "aws" {
  region = var.region
}

module "networking" {
  source = "./modules/networking"

  name_prefix          = var.name_prefix
  vpc_cidr_block       = var.vpc_cidr_block
  availability_zones   = var.availability_zones
  compute_subnet_cidrs = var.compute_subnet_cidrs
  data_subnet_cidrs    = var.data_subnet_cidrs
  db_port              = var.db_port
}

module "database" {
  source = "./modules/database"

  name_prefix       = var.name_prefix
  engine            = "postgres"
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  db_name           = var.db_name
  username          = var.db_username

  db_subnet_group_name   = module.networking.db_subnet_group_name
  vpc_security_group_ids = [module.networking.rds_security_group_id]
}

module "compute" {
  source = "./modules/compute"

  name_prefix   = var.name_prefix
  function_name = "${var.name_prefix}-api"
  runtime       = var.lambda_runtime
  handler       = var.lambda_handler
  filename      = var.lambda_filename

  subnet_ids         = module.networking.compute_subnet_ids
  security_group_ids = [module.networking.lambda_security_group_id]
  db_secret_arn      = module.database.db_master_user_secret_arn

  environment_variables = {
    DB_HOST       = module.database.db_instance_endpoint
    DB_NAME       = var.db_name
    DB_USER       = var.db_username
    DB_SECRET_ARN = module.database.db_master_user_secret_arn
  }

  api_name   = "${var.name_prefix}-api"
  stage_name = var.stage_name
}
