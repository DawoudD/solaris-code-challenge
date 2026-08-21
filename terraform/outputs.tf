output "api_endpoint" {
  description = "Public invoke URL of the API"
  value       = module.compute.api_endpoint
}

output "db_instance_endpoint" {
  description = "Connection endpoint of the RDS instance"
  value       = module.database.db_instance_endpoint
}
