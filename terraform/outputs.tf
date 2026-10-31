# =============================================================================
# Terraform Outputs — AWS VPC Peering Architecture
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Details
# -----------------------------------------------------------------------------

output "vpc_a_id" {
  description = "Existing VPC A (Requester) ID."
  value       = data.aws_vpc.vpc_a.id
}

output "vpc_a_cidr" {
  description = "Existing VPC A CIDR block."
  value       = data.aws_vpc.vpc_a.cidr_block
}

output "vpc_b_id" {
  description = "Existing VPC B (Accepter) ID."
  value       = data.aws_vpc.vpc_b.id
}

output "vpc_b_cidr" {
  description = "Existing VPC B CIDR block."
  value       = data.aws_vpc.vpc_b.cidr_block
}

# -----------------------------------------------------------------------------
# VPC Peering Connection Details
# -----------------------------------------------------------------------------

output "vpc_peering_id" {
  description = "Existing VPC Peering connection ID."
  value       = data.aws_vpc_peering_connection.existing.id
}

output "vpc_peering_status" {
  description = "Status of the VPC Peering connection (e.g., active)."
  value       = data.aws_vpc_peering_connection.existing.status
}

output "vpc_peering_requester_vpc_id" {
  description = "Requester VPC ID for the peering connection."
  value       = data.aws_vpc_peering_connection.existing.vpc_id
}

output "vpc_peering_accepter_vpc_id" {
  description = "Accepter VPC ID for the peering connection."
  value       = data.aws_vpc_peering_connection.existing.peer_vpc_id
}

# -----------------------------------------------------------------------------
# Subnet Details
# -----------------------------------------------------------------------------

output "vpc_a_public_subnet_id" {
  description = "VPC A public subnet ID hosting the Bastion host."
  value       = data.aws_subnet.vpc_a_public.id
}

output "vpc_a_private_subnet_id" {
  description = "VPC A private subnet ID (null if private tier is disabled)."
  value       = var.enable_vpc_a_private_subnet ? try(data.aws_subnet.vpc_a_private[0].id, null) : null
}

output "vpc_b_private_subnet_id" {
  description = "VPC B private subnet ID hosting the private workload."
  value       = data.aws_subnet.vpc_b_private.id
}

# -----------------------------------------------------------------------------
# Route Table Details
# -----------------------------------------------------------------------------

output "vpc_a_public_route_table_id" {
  description = "VPC A public route table ID."
  value       = data.aws_route_table.vpc_a_public.id
}

output "vpc_a_private_route_table_id" {
  description = "VPC A private route table ID (null if private tier is disabled)."
  value       = var.enable_vpc_a_private_subnet ? try(data.aws_route_table.vpc_a_private[0].id, null) : null
}

output "vpc_b_private_route_table_id" {
  description = "VPC B private route table ID."
  value       = data.aws_route_table.vpc_b_private.id
}

# -----------------------------------------------------------------------------
# Security Group Details
# -----------------------------------------------------------------------------

output "bastion_security_group_id" {
  description = "Bastion security group ID."
  value       = data.aws_security_group.bastion.id
}

output "app_a_security_group_id" {
  description = "App A security group ID (null if private tier is disabled)."
  value       = var.enable_vpc_a_private_subnet ? try(data.aws_security_group.app_a[0].id, null) : null
}

output "app_b_security_group_id" {
  description = "App B security group ID."
  value       = data.aws_security_group.app_b.id
}

# -----------------------------------------------------------------------------
# EC2 Instance Details
# -----------------------------------------------------------------------------

output "bastion_instance_id" {
  description = "Bastion EC2 instance ID."
  value       = data.aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Bastion EC2 public IPv4 address for authorized administration."
  value       = data.aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Bastion EC2 private IPv4 address."
  value       = data.aws_instance.bastion.private_ip
}

output "app_b_instance_id" {
  description = "Private App B EC2 instance ID."
  value       = data.aws_instance.app_b.id
}

output "app_b_private_ip" {
  description = "Private App B EC2 private IPv4 address."
  value       = data.aws_instance.app_b.private_ip
}
