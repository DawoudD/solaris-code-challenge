# Exposed so the compute (Lambda) module can connect to the database.

output "db_instance_endpoint" {
  description = "Connection endpoint of the RDS instance"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.this.id
}

# ARN of the AWS-managed Secrets Manager secret holding the master
# password (populated because manage_master_user_password = true).
# The compute module needs this to grant Lambda read access to it.
output "db_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the RDS master password"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
