# Production Infrastructure - Ansible

This directory contains Ansible playbooks and roles for deploying microservices to AWS EC2 instances provisioned by Terraform.

## Overview

Ansible automates the deployment and configuration of:

- **System Configuration**: Base packages, limits, logging
- **Docker Installation**: Docker Engine and Docker Compose
- **AWS CLI**: For accessing Secrets Manager and S3
- **CloudWatch Agent**: For metrics and log collection
- **Microservices Deployment**: All 8 Spring Boot services
- **Health Checks**: Automated verification of service health

## Prerequisites

### On Your Local Machine

1. **Ansible** >= 2.14
   ```bash
   # Windows (WSL)
   sudo apt update
   sudo apt install ansible
   
   # Or use pip
   pip install ansible
   ```

2. **AWS CLI** configured with credentials
   ```bash
   aws configure
   ```

3. **SSH Key** for EC2 access
   ```bash
   # Download from AWS or use your key
   chmod 400 ~/.ssh/microservices-prod-key.pem
   ```

4. **Terraform Outputs** (from infrastructure deployment)
   ```bash
   cd ../terraform
   terraform output -json > ../ansible/infrastructure-endpoints.json
   ```

## Directory Structure

```
ansible/
├── inventory/
│   ├── production.yml          # Static inventory (can be manually updated)
│   ├── dynamic_inventory.py    # Dynamic inventory from Terraform
│   └── group_vars/
│       └── all.yml             # Variables for all hosts
├── playbooks/
│   ├── deploy-all.yml          # Deploy all services
│   ├── deploy-service.yml      # Deploy single service
│   ├── rollback.yml            # Rollback deployment
│   └── health-check.yml        # Verify service health
├── roles/
│   ├── common/                 # Base system configuration
│   ├── docker/                 # Docker installation
│   ├── aws-cli/                # AWS CLI setup
│   ├── cloudwatch-agent/       # CloudWatch agent
│   └── microservices/          # Service deployment
├── templates/
│   └── env.j2                  # Environment variables template
└── README.md                   # This file
```

## Quick Start

### 1. Update Inventory

#### Option A: Use Dynamic Inventory (Recommended)

```bash
# Make script executable
chmod +x inventory/dynamic_inventory.py

# Test dynamic inventory
./inventory/dynamic_inventory.py

# Use with ansible
ansible-playbook -i inventory/dynamic_inventory.py playbooks/deploy-all.yml
```

#### Option B: Manual Inventory

Edit `inventory/production.yml` and add your EC2 instance IPs:

```yaml
app_servers:
  hosts:
    app-server-1:
      ansible_host: 54.169.123.45
    app-server-2:
      ansible_host: 54.169.123.46
    app-server-3:
      ansible_host: 54.169.123.47
```

### 2. Test Connectivity

```bash
# Test connection to all servers
ansible -i inventory/production.yml app_servers -m ping

# Or with dynamic inventory
ansible -i inventory/dynamic_inventory.py app_servers -m ping
```

### 3. Deploy All Services

```bash
# Deploy everything
ansible-playbook -i inventory/production.yml playbooks/deploy-all.yml

# With verbose output
ansible-playbook -i inventory/production.yml playbooks/deploy-all.yml -v

# Dry run (check mode)
ansible-playbook -i inventory/production.yml playbooks/deploy-all.yml --check
```

Deployment takes approximately **15-20 minutes**.

### 4. Verify Deployment

```bash
# Check service health
ansible-playbook -i inventory/production.yml playbooks/health-check.yml

# Check individual service
curl http://APP_SERVER_IP:8081/actuator/health
```

## Configuration

### Environment Variables

The deployment uses variables from multiple sources:

1. **Terraform Outputs** (infrastructure endpoints)
   - Database endpoints
   - Cache endpoints
   - Message broker endpoints
   - S3 bucket names

2. **Secrets Manager** (credentials)
   - MySQL username/password
   - MongoDB username/password
   - OpenSearch username/password

3. **Group Variables** (`inventory/group_vars/all.yml`)
   - Service ports
   - Docker image tags
   - Java configuration
   - Logging settings

4. **Environment Template** (`templates/env.j2`)
   - Spring Boot properties
   - Connection strings
   - Performance tuning

### Customizing Deployment

Edit `inventory/group_vars/all.yml`:

```yaml
# Use different Docker image tag
docker_image_tag: v1.2.3

# Adjust logging level
log_level: DEBUG

# Change Java memory settings
java_opts: "-Xms1g -Xmx4g -XX:+UseG1GC"
```

## Playbook Usage

### Deploy All Services

```bash
ansible-playbook -i inventory/production.yml playbooks/deploy-all.yml
```

### Deploy Single Service

```bash
ansible-playbook -i inventory/production.yml playbooks/deploy-service.yml \
  -e "service_name=user_service"
```

### Rolling Update (Zero Downtime)

```bash
# Update one server at a time
ansible-playbook -i inventory/production.yml playbooks/deploy-all.yml \
  --serial 1
```

### Rollback Deployment

```bash
ansible-playbook -i inventory/production.yml playbooks/rollback.yml \
  -e "service_name=user_service" \
  -e "rollback_tag=v1.0.0"
```

### Health Check Only

```bash
ansible-playbook -i inventory/production.yml playbooks/health-check.yml
```

## Advanced Usage

### Deploy to Specific Hosts

```bash
# Deploy only to app-server-1
ansible-playbook -i inventory/production.yml playbooks/deploy-all.yml \
  --limit app-server-1

# Deploy to first 2 servers
ansible-playbook -i inventory/production.yml playbooks/deploy-all.yml \
  --limit app-server-1,app-server-2
```

### Use Tags

```bash
# Only run Docker installation
ansible-playbook -i inventory/production.yml playbooks/deploy-all.yml \
  --tags docker

# Skip Docker installation
ansible-playbook -i inventory/production.yml playbooks/deploy-all.yml \
  --skip-tags docker

# Available tags: common, docker, aws-cli, cloudwatch, deploy
```

### Pass Extra Variables

```bash
ansible-playbook -i inventory/production.yml playbooks/deploy-all.yml \
  -e "docker_image_tag=latest" \
  -e "log_level=DEBUG"
```

### Run Specific Tasks

```bash
# Only update environment variables
ansible app_servers -i inventory/production.yml \
  -m template \
  -a "src=templates/env.j2 dest=/opt/microservices/.env" \
  --become
```

## Monitoring and Logs

### View Application Logs

```bash
# SSH to server
ssh -i ~/.ssh/microservices-prod-key.pem ubuntu@APP_SERVER_IP

# View service logs
sudo tail -f /opt/microservices/logs/user_service.log

# View Docker logs
sudo docker logs user_service -f
```

### CloudWatch Logs

```bash
# View logs in CloudWatch
aws logs tail /aws/microservices/microservices-platform --follow

# Filter by service
aws logs tail /aws/microservices/microservices-platform \
  --filter-pattern "user_service" --follow
```

### Check Service Status

```bash
# On server
sudo docker ps

# Check health endpoints
curl http://localhost:8081/actuator/health
curl http://localhost:8082/actuator/health
curl http://localhost:8083/actuator/health
```

## Troubleshooting

### Connection Issues

```bash
# Test SSH connection
ssh -i ~/.ssh/microservices-prod-key.pem ubuntu@APP_SERVER_IP

# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Verify inventory
ansible-inventory -i inventory/production.yml --list
```

### Service Won't Start

```bash
# Check environment file
ssh ubuntu@APP_SERVER_IP
cat /opt/microservices/.env

# Check Docker logs
sudo docker logs user_service

# Verify database connectivity
telnet mysql-endpoint 3306
```

### Database Connection Errors

```bash
# Verify Secrets Manager access
aws secretsmanager get-secret-value \
  --secret-id microservices-platform/rds/password \
  --region ap-southeast-1

# Check security groups (RDS should allow app servers)
# Check if app servers are in correct subnets
```

### High Memory Usage

```bash
# Adjust Java heap size in group_vars/all.yml
java_opts: "-Xms256m -Xmx1024m -XX:+UseG1GC"

# Redeploy services
ansible-playbook -i inventory/production.yml playbooks/deploy-all.yml
```

## Maintenance

### Update Services

```bash
# Pull latest images
ansible app_servers -i inventory/production.yml \
  -m shell \
  -a "docker-compose -f /opt/microservices/docker-compose.yml pull" \
  --become

# Restart services
ansible-playbook -i inventory/production.yml playbooks/deploy-all.yml
```

### Clean Up Docker

```bash
# Remove unused images and containers
ansible app_servers -i inventory/production.yml \
  -m shell \
  -a "docker system prune -af" \
  --become
```

### Backup Configuration

```bash
# Backup environment files
ansible app_servers -i inventory/production.yml \
  -m fetch \
  -a "src=/opt/microservices/.env dest=./backups/" \
  --become
```

## Security Best Practices

1. ✅ Use Ansible Vault for sensitive variables
2. ✅ Rotate SSH keys regularly
3. ✅ Use IAM roles instead of access keys when possible
4. ✅ Enable CloudWatch logging for audit trails
5. ✅ Keep Ansible and roles updated
6. ✅ Use `no_log: true` for sensitive tasks
7. ✅ Limit SSH access to specific IP ranges

### Using Ansible Vault

```bash
# Encrypt sensitive file
ansible-vault encrypt inventory/group_vars/all.yml

# Edit encrypted file
ansible-vault edit inventory/group_vars/all.yml

# Run playbook with vault password
ansible-playbook -i inventory/production.yml playbooks/deploy-all.yml \
  --ask-vault-pass
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Ansible
        run: pip install ansible
      
      - name: Configure SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
      
      - name: Deploy
        run: |
          cd infra/production/ansible
          ansible-playbook -i inventory/dynamic_inventory.py \
            playbooks/deploy-all.yml
```

## Support

For issues:
- **Ansible**: [Ansible Documentation](https://docs.ansible.com/)
- **AWS**: [AWS Documentation](https://docs.aws.amazon.com/)
- **Docker**: [Docker Documentation](https://docs.docker.com/)
