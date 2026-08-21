variable "name_prefix" {
  description = "Prefix used to name and tag database resources"
  type        = string
}

# Left required with no default — the engine choice was an open item in
# the brief. Will be populated as "postgres" at the root module call site.
variable "engine" {
  description = "Database engine for the RDS instance (e.g. postgres)"
  type        = string
}

variable "engine_version" {
  description = "Version of the database engine"
  type        = string
}

# db.t3.medium per the brief's "standard compute capacity" requirement,
# kept overridable rather than hardcoded into the resource.
variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Allocated storage for the RDS instance, in GB"
  type        = number
}

variable "db_name" {
  description = "Name of the initial database created on the instance"
  type        = string
}

variable "username" {
  description = "Master username for the RDS instance"
  type        = string
}

# Supplied from the networking module's outputs at the call site —
# this module doesn't create its own subnet group or security group.
variable "db_subnet_group_name" {
  description = "Name of the DB subnet group the instance should use"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "Security group IDs to attach to the RDS instance"
  type        = list(string)
}
