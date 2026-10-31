# =============================================================================
# Standalone Infrastructure Provisioning — AWS VPC Peering Lab
# =============================================================================
# This configuration provisions the complete, isolated VPC Peering architecture
# from scratch when deployed into an AWS account.
# =============================================================================

# -----------------------------------------------------------------------------
# Amazon Linux 2023 AMI Data Source
# -----------------------------------------------------------------------------

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------------------------------------
# VPC A — Requester / Public Bastion VPC
# -----------------------------------------------------------------------------

resource "aws_vpc" "vpc_a" {
  cidr_block           = var.vpc_a_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "VPC-A"
    Role = "Requester-Bastion-VPC"
  }
}

resource "aws_internet_gateway" "igw_a" {
  vpc_id = aws_vpc.vpc_a.id

  tags = {
    Name = "VPC-A-IGW"
  }
}

resource "aws_subnet" "vpc_a_public" {
  vpc_id                  = aws_vpc.vpc_a.id
  cidr_block              = var.vpc_a_public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "VPC-A-Public-Subnet"
    Type = "Public"
  }
}

# -----------------------------------------------------------------------------
# VPC B — Accepter / Private Workload VPC
# -----------------------------------------------------------------------------

resource "aws_vpc" "vpc_b" {
  cidr_block           = var.vpc_b_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "VPC-B"
    Role = "Accepter-Private-App-VPC"
  }
}

resource "aws_subnet" "vpc_b_private" {
  vpc_id                  = aws_vpc.vpc_b.id
  cidr_block              = var.vpc_b_private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "VPC-B-Private-Subnet"
    Type = "Private"
  }
}

# -----------------------------------------------------------------------------
# VPC Peering Connection
# -----------------------------------------------------------------------------

resource "aws_vpc_peering_connection" "peering" {
  vpc_id      = aws_vpc.vpc_a.id
  peer_vpc_id = aws_vpc.vpc_b.id
  auto_accept = true

  tags = {
    Name = "VPC-A-to-VPC-B-Peering"
    Side = "Requester"
  }
}

# -----------------------------------------------------------------------------
# Routing — VPC A
# -----------------------------------------------------------------------------

resource "aws_route_table" "vpc_a_public" {
  vpc_id = aws_vpc.vpc_a.id

  # Default internet route via Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_a.id
  }

  # Private peering route to VPC B CIDR
  route {
    cidr_block                = var.vpc_b_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }

  tags = {
    Name = "VPC-A-Public-Route-Table"
  }
}

resource "aws_route_table_association" "vpc_a_public" {
  subnet_id      = aws_subnet.vpc_a_public.id
  route_table_id = aws_route_table.vpc_a_public.id
}

# -----------------------------------------------------------------------------
# Routing — VPC B
# -----------------------------------------------------------------------------

resource "aws_route_table" "vpc_b_private" {
  vpc_id = aws_vpc.vpc_b.id

  # Private peering route back to VPC A CIDR
  route {
    cidr_block                = var.vpc_a_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }

  tags = {
    Name = "VPC-B-Private-Route-Table"
  }
}

resource "aws_route_table_association" "vpc_b_private" {
  subnet_id      = aws_subnet.vpc_b_private.id
  route_table_id = aws_route_table.vpc_b_private.id
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------

resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Controls inbound SSH administrative access to Bastion Host"
  vpc_id      = aws_vpc.vpc_a.id

  # Inbound SSH restricted strictly to administrator IP
  ingress {
    description = "SSH from Administrator authorized IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ssh_cidr]
  }

  # Outbound access to VPC B for bastion relaying, and outbound internet for package updates
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

resource "aws_security_group" "app_b" {
  name        = "app-b-sg"
  description = "Controls private ingress from VPC A Bastion host"
  vpc_id      = aws_vpc.vpc_b.id

  # Allow SSH strictly from the Bastion Security Group in VPC A
  ingress {
    description     = "SSH from Bastion Security Group"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Allow ICMP Echo Request (ping) strictly from VPC A CIDR
  ingress {
    description = "ICMP Echo Request from VPC A"
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [var.vpc_a_cidr]
  }

  egress {
    description = "Outbound response traffic to VPC A"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_a_cidr]
  }

  tags = {
    Name = "app-b-sg"
  }
}

# -----------------------------------------------------------------------------
# Compute Instances (EC2)
# -----------------------------------------------------------------------------

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.vpc_a_public.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = var.ssh_key_name != "" ? var.ssh_key_name : null
  associate_public_ip_address = true

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  tags = {
    Name = "Bastion-Host"
    Role = "JumpHost"
  }
}

resource "aws_instance" "app_b" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.vpc_b_private.id
  vpc_security_group_ids      = [aws_security_group.app_b.id]
  key_name                    = var.ssh_key_name != "" ? var.ssh_key_name : null
  associate_public_ip_address = false

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  tags = {
    Name = "App-B-Instance"
    Role = "PrivateWorkload"
  }
}
