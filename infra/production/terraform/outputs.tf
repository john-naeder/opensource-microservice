# ============================================================================
# OUTPUTS
# ============================================================================

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB zone ID for Route53 alias"
  value       = aws_lb.main.zone_id
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "RDS MySQL port"
  value       = aws_db_instance.main.port
}

output "rds_secret_arn" {
  description = "RDS password secret ARN"
  value       = aws_secretsmanager_secret.rds_password.arn
}

# DocumentDB Outputs
output "docdb_endpoint" {
  description = "DocumentDB cluster endpoint"
  value       = aws_docdb_cluster.main.endpoint
}

output "docdb_reader_endpoint" {
  description = "DocumentDB cluster reader endpoint"
  value       = aws_docdb_cluster.main.reader_endpoint
}

output "docdb_port" {
  description = "DocumentDB port"
  value       = aws_docdb_cluster.main.port
}

output "docdb_secret_arn" {
  description = "DocumentDB password secret ARN"
  value       = aws_secretsmanager_secret.docdb_password.arn
}

# ElastiCache Outputs
output "redis_configuration_endpoint" {
  description = "Redis configuration endpoint"
  value       = aws_elasticache_replication_group.main.configuration_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = 6379
}

# MSK Outputs
output "msk_bootstrap_brokers_tls" {
  description = "MSK Kafka bootstrap brokers (TLS)"
  value       = aws_msk_cluster.main.bootstrap_brokers_tls
}

output "msk_zookeeper_connect_string" {
  description = "MSK Zookeeper connection string"
  value       = aws_msk_cluster.main.zookeeper_connect_string
}

# OpenSearch Outputs
output "opensearch_endpoint" {
  description = "OpenSearch domain endpoint"
  value       = aws_opensearch_domain.main.endpoint
}

output "opensearch_kibana_endpoint" {
  description = "OpenSearch Kibana endpoint"
  value       = aws_opensearch_domain.main.kibana_endpoint
}

output "opensearch_secret_arn" {
  description = "OpenSearch password secret ARN"
  value       = aws_secretsmanager_secret.opensearch_password.arn
}

# S3 Outputs
output "uploads_bucket_name" {
  description = "S3 bucket name for file uploads"
  value       = aws_s3_bucket.uploads.id
}

output "uploads_bucket_arn" {
  description = "S3 bucket ARN for file uploads"
  value       = aws_s3_bucket.uploads.arn
}

# Auto Scaling Group Outputs
output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.app.name
}

output "asg_desired_capacity" {
  description = "Auto Scaling Group desired capacity"
  value       = aws_autoscaling_group.app.desired_capacity
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Application security group ID"
  value       = aws_security_group.app.id
}

# Connection Strings (for Ansible inventory)
output "connection_info" {
  description = "Connection information for all services"
  value = {
    mysql = {
      endpoint   = aws_db_instance.main.endpoint
      port       = aws_db_instance.main.port
      secret_arn = aws_secretsmanager_secret.rds_password.arn
    }
    mongodb = {
      endpoint   = aws_docdb_cluster.main.endpoint
      port       = aws_docdb_cluster.main.port
      secret_arn = aws_secretsmanager_secret.docdb_password.arn
    }
    redis = {
      endpoint = aws_elasticache_replication_group.main.configuration_endpoint_address
      port     = 6379
    }
    kafka = {
      brokers = aws_msk_cluster.main.bootstrap_brokers_tls
    }
    opensearch = {
      endpoint   = aws_opensearch_domain.main.endpoint
      secret_arn = aws_secretsmanager_secret.opensearch_password.arn
    }
    s3 = {
      bucket = aws_s3_bucket.uploads.id
    }
    alb = {
      dns_name = aws_lb.main.dns_name
    }
  }
  sensitive = true
}
