# -----------------------------------------------------------------------------
# AWS Region & Provider Configuration
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS target region where resources reside."
  type        = string
  default     = "eu-north-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "The aws_region variable must follow standard AWS region naming convention (e.g., eu-north-1, us-east-1)."
  }
}

variable "default_tags" {
  description = "Default resource tags applied across AWS provider resources."
  type        = map(string)
  default = {
    Project     = "AWS-VPC-Peering"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

# -----------------------------------------------------------------------------
# VPC Configurations
# -----------------------------------------------------------------------------

variable "vpc_a_cidr" {
  description = "IPv4 CIDR block of VPC A (Requester / Public Bastion VPC)."
  type        = string
  default     = "10.10.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_a_cidr))
    error_message = "The vpc_a_cidr must be a valid IPv4 CIDR block."
  }
}

variable "vpc_b_cidr" {
  description = "IPv4 CIDR block of VPC B (Accepter / Private App VPC)."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_b_cidr))
    error_message = "The vpc_b_cidr must be a valid IPv4 CIDR block."
  }
}

variable "vpc_a_name_tag" {
  description = "Name tag filter value used to identify VPC A in AWS."
  type        = string
  default     = "VPC-A"
}

variable "vpc_b_name_tag" {
  description = "Name tag filter value used to identify VPC B in AWS."
  type        = string
  default     = "VPC-B"
}

# -----------------------------------------------------------------------------
# Subnet Configurations
# -----------------------------------------------------------------------------

variable "vpc_a_public_subnet_cidr" {
  description = "IPv4 CIDR block for VPC A public subnet hosting the bastion instance."
  type        = string
  default     = "10.10.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.vpc_a_public_subnet_cidr))
    error_message = "The vpc_a_public_subnet_cidr must be a valid IPv4 CIDR block."
  }
}

variable "vpc_a_public_subnet_name_tag" {
  description = "Name tag filter value for VPC A public subnet."
  type        = string
  default     = "VPC-A-Public-Subnet"
}

variable "vpc_b_private_subnet_cidr" {
  description = "IPv4 CIDR block for VPC B private subnet hosting the target workload."
  type        = string
  default     = "10.20.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.vpc_b_private_subnet_cidr))
    error_message = "The vpc_b_private_subnet_cidr must be a valid IPv4 CIDR block."
  }
}

variable "vpc_b_private_subnet_name_tag" {
  description = "Name tag filter value for VPC B private subnet."
  type        = string
  default     = "VPC-B-Private-Subnet"
}

# -----------------------------------------------------------------------------
# Optional VPC A Private Subnet Support
# -----------------------------------------------------------------------------

variable "enable_vpc_a_private_subnet" {
  description = "Flag to enable discovery of an optional private subnet and associated security group in VPC A."
  type        = bool
  default     = false
}

variable "vpc_a_private_subnet_cidr" {
  description = "IPv4 CIDR block for VPC A private subnet (if enabled)."
  type        = string
  default     = "10.10.2.0/24"
}

variable "vpc_a_private_subnet_name_tag" {
  description = "Name tag filter value for VPC A private subnet (if enabled)."
  type        = string
  default     = "VPC-A-Private-Subnet"
}

variable "app_a_security_group_name" {
  description = "Group name filter for optional App A security group in VPC A."
  type        = string
  default     = "app-a-sg"
}

# -----------------------------------------------------------------------------
# VPC Peering
# -----------------------------------------------------------------------------

variable "peering_connection_id" {
  description = "Specific VPC Peering Connection ID (e.g. pcx-xxxx). If left empty, discovery uses VPC IDs and active status."
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------

variable "bastion_security_group_name" {
  description = "Group name filter for the Bastion Host Security Group."
  type        = string
  default     = "bastion-sg"
}

variable "app_b_security_group_name" {
  description = "Group name filter for the VPC B Private App Security Group."
  type        = string
  default     = "app-b-sg"
}

# -----------------------------------------------------------------------------
# EC2 Instances
# -----------------------------------------------------------------------------

variable "bastion_instance_name_tag" {
  description = "Name tag filter value for the Bastion Host EC2 instance."
  type        = string
  default     = "Bastion-Host"
}

variable "app_b_instance_name_tag" {
  description = "Name tag filter value for the VPC B App EC2 instance."
  type        = string
  default     = "App-B-Instance"
}
