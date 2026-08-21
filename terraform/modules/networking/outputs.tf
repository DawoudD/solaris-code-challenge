# Exposed so the compute (Lambda) and database (RDS) modules can
# reference this module's resources without duplicating them.

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "compute_subnet_ids" {
  description = "IDs of the private compute (Lambda) subnets"
  value       = aws_subnet.compute[*].id
}

output "data_subnet_ids" {
  description = "IDs of the private data (RDS) subnets"
  value       = aws_subnet.data[*].id
}

output "lambda_security_group_id" {
  description = "ID of the Lambda security group"
  value       = aws_security_group.lambda.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "Name of the RDS DB subnet group"
  value       = aws_db_subnet_group.this.name
}
