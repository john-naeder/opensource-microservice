#!/bin/bash
# ============================================================================
# EC2 User Data Script - Bootstrap Application Servers
# ============================================================================

set -e

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install AWS CLI
apt-get install -y awscli

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

# Create application directory
mkdir -p /opt/microservices
cd /opt/microservices

# Fetch database credentials from Secrets Manager
export MYSQL_CREDS=$(aws secretsmanager get-secret-value --secret-id ${project_name}/rds/password --region ${region} --query SecretString --output text)
export DOCDB_CREDS=$(aws secretsmanager get-secret-value --secret-id ${project_name}/docdb/password --region ${region} --query SecretString --output text)
export OPENSEARCH_CREDS=$(aws secretsmanager get-secret-value --secret-id ${project_name}/opensearch/password --region ${region} --query SecretString --output text)

# Extract credentials
export MYSQL_HOST=$(echo $MYSQL_CREDS | jq -r '.host')
export MYSQL_USER=$(echo $MYSQL_CREDS | jq -r '.username')
export MYSQL_PASSWORD=$(echo $MYSQL_CREDS | jq -r '.password')
export MYSQL_PORT=$(echo $MYSQL_CREDS | jq -r '.port')

export DOCDB_HOST=$(echo $DOCDB_CREDS | jq -r '.host')
export DOCDB_USER=$(echo $DOCDB_CREDS | jq -r '.username')
export DOCDB_PASSWORD=$(echo $DOCDB_CREDS | jq -r '.password')
export DOCDB_PORT=$(echo $DOCDB_CREDS | jq -r '.port')

export OPENSEARCH_HOST=$(echo $OPENSEARCH_CREDS | jq -r '.endpoint')
export OPENSEARCH_USER=$(echo $OPENSEARCH_CREDS | jq -r '.username')
export OPENSEARCH_PASSWORD=$(echo $OPENSEARCH_CREDS | jq -r '.password')

# Create environment file
cat > /opt/microservices/.env << EOF
# Infrastructure Endpoints
SPRING_DATASOURCE_URL=jdbc:mysql://$MYSQL_HOST:$MYSQL_PORT
SPRING_DATASOURCE_USERNAME=$MYSQL_USER
SPRING_DATASOURCE_PASSWORD=$MYSQL_PASSWORD

SPRING_DATA_MONGODB_HOST=$DOCDB_HOST
SPRING_DATA_MONGODB_PORT=$DOCDB_PORT
SPRING_DATA_MONGODB_USERNAME=$DOCDB_USER
SPRING_DATA_MONGODB_PASSWORD=$DOCDB_PASSWORD

SPRING_DATA_REDIS_HOST=${redis_endpoint}
SPRING_DATA_REDIS_PORT=6379

SPRING_KAFKA_BOOTSTRAP_SERVERS=${kafka_brokers}

SPRING_ELASTICSEARCH_URIS=https://${opensearch_endpoint}:443
SPRING_ELASTICSEARCH_USERNAME=$OPENSEARCH_USER
SPRING_ELASTICSEARCH_PASSWORD=$OPENSEARCH_PASSWORD

# S3 Configuration
FILE_UPLOAD_DIR=s3://${project_name}-uploads
AWS_REGION=${region}

# Application Configuration
SERVER_PORT=8080
SPRING_PROFILES_ACTIVE=production
EOF

# Note: Actual service deployment will be handled by Ansible
# This script only bootstraps the instance with required software and configuration

echo "Bootstrap completed successfully"
