########################################
# VPC Outputs
########################################
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

########################################
# Security Group Outputs
########################################
output "bastion_security_group_id" {
  description = "The ID of the bastion host security group"
  value       = aws_security_group.bastion_sg.id
}

output "web_security_group_id" {
  description = "The ID of the web server security group"
  value       = aws_security_group.web_sg.id
}

output "rds_security_group_id" {
  description = "The ID of the RDS security group"
  value       = aws_security_group.rds_sg.id
}

########################################
# EC2 Outputs
########################################
output "bastion_public_ip" {
  description = "The public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_dns" {
  description = "The public DNS name of the bastion host"
  value       = aws_instance.bastion.public_dns
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.web-server.id
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = aws_launch_template.web-server.latest_version
}

########################################
# Auto Scaling Group Outputs
########################################
output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "asg_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.arn
}

########################################
# RDS Outputs
########################################
output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.myrds.endpoint
}

output "rds_db_name" {
  description = "The name of the database"
  value       = aws_db_instance.myrds.db_name
}

output "rds_port" {
  description = "The port the database is listening on"
  value       = aws_db_instance.myrds.port
}

########################################
# Connection Instructions
########################################
output "bastion_connection_string" {
  description = "Command to connect to the bastion host"
  value       = "ssh ec2-user@${aws_instance.bastion.public_dns}"
}

output "rds_connection_info" {
  description = "RDS connection information"
  value       = {
    endpoint = aws_db_instance.myrds.endpoint
    port     = aws_db_instance.myrds.port
    database = aws_db_instance.myrds.db_name
    username = aws_db_instance.myrds.username
  }
  sensitive = true  # Marks this output as sensitive
}