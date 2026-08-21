# --- RDS instance ---
# Sits in the data-tier private subnets via db_subnet_group_name, and is
# only reachable from Lambda via vpc_security_group_ids (both supplied by
# the networking module) — no direct internet exposure.
resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-db"
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  db_name           = var.db_name
  username          = var.username

  # AWS creates and manages the master password in Secrets Manager —
  # avoids us having to create/store a separate secret resource.
  manage_master_user_password = true

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = false

  # Defaults to false, which requires naming a final_snapshot_identifier
  # on every deletion — skipping it since this is disposable infrastructure.
  skip_final_snapshot = true

  tags = {
    Name = "${var.name_prefix}-db"
  }
}
