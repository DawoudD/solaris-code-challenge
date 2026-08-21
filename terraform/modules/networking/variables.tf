variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "name_prefix" {
  description = "Prefix used to name and tag networking resources"
  type        = string
}

# AZs the subnets will be spread across. RDS DB subnet groups require
# subnets in at least 2 AZs, so this list must have a minimum of 2 entries.
variable "availability_zones" {
  description = "List of availability zones to spread subnets across"
  type        = list(string)
}

# One CIDR per AZ — Lambda's private subnets (compute tier).
# Kept separate from the data tier subnets so compute and data can be
# managed/extended independently (e.g. different NACLs later).
variable "compute_subnet_cidrs" {
  description = "CIDR blocks for the private compute (Lambda) subnets, one per AZ"
  type        = list(string)
}

# One CIDR per AZ — RDS's private subnets (data tier).
variable "data_subnet_cidrs" {
  description = "CIDR blocks for the private data (RDS) subnets, one per AZ"
  type        = list(string)
}

# The DB engine (and therefore its default port) isn't confirmed yet,
# so this is left as a required input rather than hardcoded/defaulted.
variable "db_port" {
  description = "Port the RDS instance listens on, used in the RDS security group ingress rule"
  type        = number
}
