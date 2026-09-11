resource "aws_db_subnet_group" "this" {
  name       = "${var.project_prefix}-db-subnets"
  subnet_ids = var.private_database_subnet_ids

  tags = {
    Name = "${var.project_prefix}-db-subnets"
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.project_prefix}-postgres"
  engine                 = "postgres"
  engine_version         = "18.3"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp3"
  storage_encrypted      = true
  db_name                = "taskmanager"
  username               = var.database_master_username
  password               = var.database_master_password
  port                   = 5432
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false
  multi_az               = false
  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true
  performance_insights_enabled = false
  monitoring_interval          = 0

  tags = {
    Name = "${var.project_prefix}-postgres"
  }
}
