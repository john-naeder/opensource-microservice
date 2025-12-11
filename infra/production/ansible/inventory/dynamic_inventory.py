#!/usr/bin/env python3
"""
Dynamic Ansible Inventory from Terraform Outputs
Reads Terraform state and generates Ansible inventory
"""

import json
import subprocess
import sys

def get_terraform_outputs():
    """Get Terraform outputs as JSON"""
    try:
        result = subprocess.run(
            ['terraform', 'output', '-json'],
            cwd='../../terraform',
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error getting Terraform outputs: {e}", file=sys.stderr)
        sys.exit(1)

def get_ec2_instances():
    """Get EC2 instances from Auto Scaling Group"""
    try:
        # Get ASG name from Terraform
        result = subprocess.run(
            ['terraform', 'output', '-raw', 'asg_name'],
            cwd='../../terraform',
            capture_output=True,
            text=True,
            check=True
        )
        asg_name = result.stdout.strip()
        
        # Get instances in ASG
        result = subprocess.run(
            ['aws', 'autoscaling', 'describe-auto-scaling-groups',
             '--auto-scaling-group-names', asg_name,
             '--query', 'AutoScalingGroups[0].Instances[*].InstanceId',
             '--output', 'json'],
            capture_output=True,
            text=True,
            check=True
        )
        instance_ids = json.loads(result.stdout)
        
        # Get instance details
        result = subprocess.run(
            ['aws', 'ec2', 'describe-instances',
             '--instance-ids'] + instance_ids +
            ['--query', 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,PrivateIpAddress]',
             '--output', 'json'],
            capture_output=True,
            text=True,
            check=True
        )
        instances = json.loads(result.stdout)
        
        # Flatten nested list
        return [inst for reservation in instances for inst in reservation]
        
    except subprocess.CalledProcessError as e:
        print(f"Error getting EC2 instances: {e}", file=sys.stderr)
        return []

def generate_inventory():
    """Generate Ansible inventory from Terraform state"""
    tf_outputs = get_terraform_outputs()
    ec2_instances = get_ec2_instances()
    
    inventory = {
        '_meta': {
            'hostvars': {}
        },
        'all': {
            'vars': {
                'ansible_user': 'ubuntu',
                'ansible_python_interpreter': '/usr/bin/python3',
                'environment_name': 'production',
                # Infrastructure endpoints
                'mysql_endpoint': tf_outputs.get('rds_endpoint', {}).get('value', ''),
                'mysql_port': tf_outputs.get('rds_port', {}).get('value', 3306),
                'docdb_endpoint': tf_outputs.get('docdb_endpoint', {}).get('value', ''),
                'docdb_port': tf_outputs.get('docdb_port', {}).get('value', 27017),
                'redis_endpoint': tf_outputs.get('redis_configuration_endpoint', {}).get('value', ''),
                'redis_port': tf_outputs.get('redis_port', {}).get('value', 6379),
                'kafka_brokers': tf_outputs.get('msk_bootstrap_brokers_tls', {}).get('value', ''),
                'opensearch_endpoint': tf_outputs.get('opensearch_endpoint', {}).get('value', ''),
                's3_bucket': tf_outputs.get('uploads_bucket_name', {}).get('value', ''),
                'alb_dns': tf_outputs.get('alb_dns_name', {}).get('value', ''),
                # Secret ARNs
                'mysql_secret_arn': tf_outputs.get('rds_secret_arn', {}).get('value', ''),
                'docdb_secret_arn': tf_outputs.get('docdb_secret_arn', {}).get('value', ''),
                'opensearch_secret_arn': tf_outputs.get('opensearch_secret_arn', {}).get('value', ''),
            }
        },
        'app_servers': {
            'hosts': [],
            'vars': {
                'ansible_connection': 'ssh'
            }
        }
    }
    
    # Add EC2 instances to inventory
    for idx, instance in enumerate(ec2_instances):
        instance_id, public_ip, private_ip = instance
        host_name = f"app-server-{idx + 1}"
        
        inventory['app_servers']['hosts'].append(host_name)
        inventory['_meta']['hostvars'][host_name] = {
            'ansible_host': public_ip or private_ip,
            'instance_id': instance_id,
            'private_ip': private_ip,
            'public_ip': public_ip
        }
    
    return inventory

if __name__ == '__main__':
    inventory = generate_inventory()
    print(json.dumps(inventory, indent=2))
