# =============================================================================
# AWS VPC Peering Discovery & Audit Configuration
# =============================================================================
# This Terraform configuration uses data sources to discover, query, and audit
# existing AWS VPC Peering lab infrastructure without creating, mutating, or
# destroying resources.
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Data Sources
# -----------------------------------------------------------------------------

data "aws_vpc" "vpc_a" {
  filter {
    name   = "cidr-block"
    values = [var.vpc_a_cidr]
  }

  filter {
    name   = "tag:Name"
    values = [var.vpc_a_name_tag]
  }
}

data "aws_vpc" "vpc_b" {
  filter {
    name   = "cidr-block"
    values = [var.vpc_b_cidr]
  }

  filter {
    name   = "tag:Name"
    values = [var.vpc_b_name_tag]
  }
}

# -----------------------------------------------------------------------------
# VPC Peering Connection Data Source
# -----------------------------------------------------------------------------

data "aws_vpc_peering_connection" "existing" {
  id = var.peering_connection_id != "" ? var.peering_connection_id : null

  vpc_id      = var.peering_connection_id == "" ? data.aws_vpc.vpc_a.id : null
  peer_vpc_id = var.peering_connection_id == "" ? data.aws_vpc.vpc_b.id : null
  status      = "active"
}

# -----------------------------------------------------------------------------
# Subnet Data Sources
# -----------------------------------------------------------------------------

data "aws_subnet" "vpc_a_public" {
  vpc_id     = data.aws_vpc.vpc_a.id
  cidr_block = var.vpc_a_public_subnet_cidr

  filter {
    name   = "tag:Name"
    values = [var.vpc_a_public_subnet_name_tag]
  }
}

data "aws_subnet" "vpc_b_private" {
  vpc_id     = data.aws_vpc.vpc_b.id
  cidr_block = var.vpc_b_private_subnet_cidr

  filter {
    name   = "tag:Name"
    values = [var.vpc_b_private_subnet_name_tag]
  }
}

data "aws_subnet" "vpc_a_private" {
  count      = var.enable_vpc_a_private_subnet ? 1 : 0
  vpc_id     = data.aws_vpc.vpc_a.id
  cidr_block = var.vpc_a_private_subnet_cidr

  filter {
    name   = "tag:Name"
    values = [var.vpc_a_private_subnet_name_tag]
  }
}

# -----------------------------------------------------------------------------
# Route Table Data Sources
# -----------------------------------------------------------------------------

data "aws_route_table" "vpc_a_public" {
  subnet_id = data.aws_subnet.vpc_a_public.id
}

data "aws_route_table" "vpc_b_private" {
  subnet_id = data.aws_subnet.vpc_b_private.id
}

data "aws_route_table" "vpc_a_private" {
  count     = var.enable_vpc_a_private_subnet ? 1 : 0
  subnet_id = data.aws_subnet.vpc_a_private[0].id
}

# -----------------------------------------------------------------------------
# Security Group Data Sources
# -----------------------------------------------------------------------------

data "aws_security_group" "bastion" {
  vpc_id = data.aws_vpc.vpc_a.id

  filter {
    name   = "group-name"
    values = [var.bastion_security_group_name]
  }
}

data "aws_security_group" "app_b" {
  vpc_id = data.aws_vpc.vpc_b.id

  filter {
    name   = "group-name"
    values = [var.app_b_security_group_name]
  }
}

data "aws_security_group" "app_a" {
  count  = var.enable_vpc_a_private_subnet ? 1 : 0
  vpc_id = data.aws_vpc.vpc_a.id

  filter {
    name   = "group-name"
    values = [var.app_a_security_group_name]
  }
}

# -----------------------------------------------------------------------------
# EC2 Instance Data Sources
# -----------------------------------------------------------------------------

data "aws_instance" "bastion" {
  filter {
    name   = "subnet-id"
    values = [data.aws_subnet.vpc_a_public.id]
  }

  filter {
    name   = "instance-state-name"
    values = ["running", "stopped"]
  }

  filter {
    name   = "tag:Name"
    values = [var.bastion_instance_name_tag]
  }
}

data "aws_instance" "app_b" {
  filter {
    name   = "subnet-id"
    values = [data.aws_subnet.vpc_b_private.id]
  }

  filter {
    name   = "instance-state-name"
    values = ["running", "stopped"]
  }

  filter {
    name   = "tag:Name"
    values = [var.app_b_instance_name_tag]
  }
}
