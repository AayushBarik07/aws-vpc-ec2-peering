# =============================================================================
# Outputs — Standalone VPC Peering Lab Provisioning
# =============================================================================

output "vpc_a_id" {
  description = "VPC A (Requester) ID."
  value       = aws_vpc.vpc_a.id
}

output "vpc_a_cidr" {
  description = "VPC A CIDR block."
  value       = aws_vpc.vpc_a.cidr_block
}

output "vpc_b_id" {
  description = "VPC B (Accepter) ID."
  value       = aws_vpc.vpc_b.id
}

output "vpc_b_cidr" {
  description = "VPC B CIDR block."
  value       = aws_vpc.vpc_b.cidr_block
}

output "vpc_peering_id" {
  description = "VPC Peering Connection ID."
  value       = aws_vpc_peering_connection.peering.id
}

output "vpc_peering_status" {
  description = "Acceptance status of the VPC Peering connection."
  value       = aws_vpc_peering_connection.peering.accept_status
}

output "vpc_a_public_subnet_id" {
  description = "VPC A Public Subnet ID."
  value       = aws_subnet.vpc_a_public.id
}

output "vpc_b_private_subnet_id" {
  description = "VPC B Private Subnet ID."
  value       = aws_subnet.vpc_b_private.id
}

output "vpc_a_route_table_id" {
  description = "VPC A Public Route Table ID."
  value       = aws_route_table.vpc_a_public.id
}

output "vpc_b_route_table_id" {
  description = "VPC B Private Route Table ID."
  value       = aws_route_table.vpc_b_private.id
}

output "bastion_security_group_id" {
  description = "Bastion Security Group ID."
  value       = aws_security_group.bastion.id
}

output "app_b_security_group_id" {
  description = "App B Security Group ID."
  value       = aws_security_group.app_b.id
}

output "bastion_instance_id" {
  description = "Bastion EC2 Instance ID."
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Bastion public IPv4 address for SSH administration."
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Bastion private IPv4 address."
  value       = aws_instance.bastion.private_ip
}

output "app_b_instance_id" {
  description = "Private App B EC2 Instance ID."
  value       = aws_instance.app_b.id
}

output "app_b_private_ip" {
  description = "Private App B EC2 private IPv4 address."
  value       = aws_instance.app_b.private_ip
}

output "ssh_bastion_command" {
  description = "Helper SSH command to connect to Bastion."
  value       = "ssh -i <your-key.pem> ec2-user@${aws_instance.bastion.public_ip}"
}

output "ssh_app_b_jump_command" {
  description = "Helper SSH Jump command to reach App B through Bastion."
  value       = "ssh -J ec2-user@${aws_instance.bastion.public_ip} -i <your-key.pem> ec2-user@${aws_instance.app_b.private_ip}"
}
