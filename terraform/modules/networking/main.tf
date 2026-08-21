resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

# --- Compute tier subnets (Lambda) ---
# Private: Lambda is invoked externally via API Gateway, not via inbound
# network traffic, so these subnets have no route to/from the internet.
# One subnet per AZ, count-indexed against availability_zones/compute_subnet_cidrs.
resource "aws_subnet" "compute" {
  count = length(var.compute_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.compute_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.name_prefix}-compute-${var.availability_zones[count.index]}"
    Tier = "compute"
  }
}

# --- Data tier subnets (RDS) ---
# Kept separate from the compute subnets so the data tier can be managed
# and extended independently of compute (e.g. future services sharing the DB).
resource "aws_subnet" "data" {
  count = length(var.data_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.data_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.name_prefix}-data-${var.availability_zones[count.index]}"
    Tier = "data"
  }
}

# No aws_route_table / aws_route_table_association resources here —
# all subnets use the VPC's default route table, which only contains
# the implicit "local" route needed for in-VPC traffic (Lambda <-> RDS).
# There's no internet egress requirement, so no NAT/IGW routes are added.

# --- Lambda security group ---
# No inline ingress/egress rules here — the Lambda and RDS security groups
# each reference the other, which creates a dependency cycle if the rules
# are declared inline (both SGs would need to exist before either could be
# created). Declaring the rules as separate resources below breaks the cycle:
# both security groups are created first, then the cross-referencing rules
# are attached afterward.
resource "aws_security_group" "lambda" {
  name_prefix = "${var.name_prefix}-lambda-"
  description = "Security group for the Lambda function"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-lambda-sg"
  }
}

# --- RDS security group ---
# Ingress restricted to traffic from the Lambda security group only —
# no CIDR-based rules, so nothing other than the Lambda function can
# reach the database, even though they're both in private subnets.
resource "aws_security_group" "rds" {
  name_prefix = "${var.name_prefix}-rds-"
  description = "Security group for the RDS instance"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }
}

# Lambda -> RDS on the DB port. Egress is required so Lambda can open
# connections out to RDS; Lambda has no ingress rules since it's invoked
# by API Gateway (outside the VPC), not by inbound network traffic.
resource "aws_vpc_security_group_egress_rule" "lambda_to_rds" {
  security_group_id = aws_security_group.lambda.id

  description                  = "Allow outbound traffic to the RDS security group on the DB port"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds.id
}

# RDS accepts inbound only from the Lambda security group, on the DB port.
resource "aws_vpc_security_group_ingress_rule" "rds_from_lambda" {
  security_group_id = aws_security_group.rds.id

  description                  = "Allow inbound traffic from the Lambda security group on the DB port"
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.lambda.id
}

# --- RDS subnet group ---
# Groups the data-tier private subnets so RDS can be placed across
# multiple AZs. Required by AWS even for a single-AZ RDS instance.
resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.data[*].id

  tags = {
    Name = "${var.name_prefix}-db-subnet-group"
  }
}
