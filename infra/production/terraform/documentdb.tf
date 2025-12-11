# ============================================================================
# DocumentDB (MongoDB compatible)
# ============================================================================

resource "aws_docdb_subnet_group" "main" {
  name       = "${var.project_name}-docdb-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-docdb-subnet-group"
  }
}

resource "aws_docdb_cluster_parameter_group" "main" {
  family = "docdb5.0"
  name   = "${var.project_name}-docdb-params"

  parameter {
    name  = "tls"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-docdb-params"
  }
}

resource "random_password" "docdb_password" {
  length  = 32
  special = true
}

resource "aws_docdb_cluster" "main" {
  cluster_identifier      = "${var.project_name}-docdb"
  engine                  = "docdb"
  master_username         = "admin"
  master_password         = random_password.docdb_password.result
  db_subnet_group_name    = aws_docdb_subnet_group.main.name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name
  vpc_security_group_ids  = [aws_security_group.docdb.id]

  backup_retention_period = var.backup_retention_days
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"

  storage_encrypted = true
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.project_name}-docdb-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  enabled_cloudwatch_logs_exports = ["audit", "profiler"]

  tags = {
    Name = "${var.project_name}-docdb"
  }
}

resource "aws_docdb_cluster_instance" "main" {
  count              = var.docdb_instance_count
  identifier         = "${var.project_name}-docdb-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.docdb_instance_class

  tags = {
    Name = "${var.project_name}-docdb-instance-${count.index + 1}"
  }
}

# Store DocumentDB credentials in Secrets Manager
resource "aws_secretsmanager_secret" "docdb_password" {
  name                    = "${var.project_name}/docdb/password"
  recovery_window_in_days = 30

  tags = {
    Name = "${var.project_name}-docdb-password"
  }
}

resource "aws_secretsmanager_secret_version" "docdb_password" {
  secret_id = aws_secretsmanager_secret.docdb_password.id
  secret_string = jsonencode({
    username = aws_docdb_cluster.main.master_username
    password = random_password.docdb_password.result
    host     = aws_docdb_cluster.main.endpoint
    port     = aws_docdb_cluster.main.port
  })
}
