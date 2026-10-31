# -----------------------------------------------------------------------------
# AWS Region & Global Settings
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "Target AWS region for deploying the VPC Peering lab."
  type        = string
  default     = "eu-north-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "The aws_region variable must follow standard AWS region naming convention."
  }
}

variable "default_tags" {
  description = "Default resource tags applied across all lab resources."
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
  description = "IPv4 CIDR block for VPC A (Requester / Public Bastion VPC)."
  type        = string
  default     = "10.10.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_a_cidr))
    error_message = "The vpc_a_cidr must be a valid IPv4 CIDR block."
  }
}

variable "vpc_b_cidr" {
  description = "IPv4 CIDR block for VPC B (Accepter / Private Workload VPC)."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_b_cidr))
    error_message = "The vpc_b_cidr must be a valid IPv4 CIDR block."
  }
}

variable "vpc_a_public_subnet_cidr" {
  description = "IPv4 CIDR block for VPC A Public Subnet."
  type        = string
  default     = "10.10.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.vpc_a_public_subnet_cidr))
    error_message = "The vpc_a_public_subnet_cidr must be a valid IPv4 CIDR block."
  }
}

variable "vpc_b_private_subnet_cidr" {
  description = "IPv4 CIDR block for VPC B Private Subnet."
  type        = string
  default     = "10.20.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.vpc_b_private_subnet_cidr))
    error_message = "The vpc_b_private_subnet_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zone" {
  description = "Availability zone within the region for subnet placement (e.g. eu-north-1a)."
  type        = string
  default     = "eu-north-1a"
}

# -----------------------------------------------------------------------------
# Compute & Security Configurations
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type for both Bastion and App nodes."
  type        = string
  default     = "t3.micro"
}

variable "admin_ssh_cidr" {
  description = "Trusted IPv4 CIDR block permitted to SSH into the Bastion host. DO NOT set to 0.0.0.0/0 in production."
  type        = string
  default     = "127.0.0.1/32"

  validation {
    condition     = can(cidrnetmask(var.admin_ssh_cidr))
    error_message = "The admin_ssh_cidr must be a valid IPv4 CIDR block."
  }
}

variable "ssh_key_name" {
  description = "Existing AWS EC2 Key Pair name to associate with the instances for SSH access."
  type        = string
  default     = ""
}
