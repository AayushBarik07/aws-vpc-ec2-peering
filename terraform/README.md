# Terraform Infrastructure & Audit Guide

This directory houses the Terraform configurations for the **AWS VPC Peering — Private Network Connectivity** project.

---

## Architecture & Operational Modes

To accommodate both **pre-existing manually configured AWS environments** and **reproducible automated deployments**, the project is structured into two cleanly separated modes:

```
terraform/
├── .terraform.lock.hcl           # Pinned provider dependency versions
├── versions.tf                   # Terraform and AWS provider definitions
├── variables.tf                  # Variable definitions with types & validation
├── main.tf                       # [Mode 1] Discovery & Audit via AWS Data Sources
├── outputs.tf                    # Structured outputs referencing discovered resources
├── terraform.tfvars.example      # Example configuration template for local tuning
├── README.md                     # This documentation guide
└── iac-provisioning/             # [Mode 2] Standalone IaC deployment from scratch
    ├── versions.tf
    ├── variables.tf
    ├── main.tf
    ├── outputs.tf
    ├── terraform.tfvars.example
    └── README.md
```

### Mode 1: Discovery & Audit (Root `/terraform`)
- **Purpose**: Safely inspects, verifies, and exports attributes of existing AWS resources without creating, mutating, or destroying state.
- **Mechanism**: Utilizes Terraform `data "aws_*"` sources filtered by CIDRs, tags, and IDs.
- **Safety**: Safe to run against live AWS environments because it does not manage resource lifecycles or propose destructive actions.

### Mode 2: Standalone Provisioning (`/terraform/iac-provisioning`)
- **Purpose**: Provisions the entire dual-VPC lab from scratch (VPCs, Subnets, Internet Gateway, Peering Connection, Route Tables, Security Groups, and EC2 instances).
- **Mechanism**: Declarative `resource "aws_*"` blocks.
- **Location**: See [iac-provisioning/README.md](iac-provisioning/README.md).

---

## Root Configuration Reference (Mode 1: Discovery)

### Providers

| Name | Source | Version Constraint |
|---|---|---|
| `aws` | `hashicorp/aws` | `~> 5.0` |

### Input Variables

| Variable | Description | Type | Default | Validation |
|---|---|---|---|---|
| `aws_region` | AWS region where resources reside | `string` | `"eu-north-1"` | Regex region format |
| `vpc_a_cidr` | IPv4 CIDR block for VPC A | `string` | `"10.10.0.0/16"` | Valid CIDR |
| `vpc_b_cidr` | IPv4 CIDR block for VPC B | `string` | `"10.20.0.0/16"` | Valid CIDR |
| `vpc_a_name_tag` | Tag:Name filter for VPC A | `string` | `"VPC-A"` | None |
| `vpc_b_name_tag` | Tag:Name filter for VPC B | `string` | `"VPC-B"` | None |
| `vpc_a_public_subnet_cidr` | CIDR block for VPC A public subnet | `string` | `"10.10.1.0/24"` | Valid CIDR |
| `vpc_a_public_subnet_name_tag` | Tag:Name filter for VPC A public subnet | `string` | `"VPC-A-Public-Subnet"` | None |
| `vpc_b_private_subnet_cidr` | CIDR block for VPC B private subnet | `string` | `"10.20.1.0/24"` | Valid CIDR |
| `vpc_b_private_subnet_name_tag` | Tag:Name filter for VPC B private subnet | `string` | `"VPC-B-Private-Subnet"` | None |
| `enable_vpc_a_private_subnet` | Flag to query optional private tier in VPC A | `bool` | `false` | None |
| `bastion_security_group_name` | Name filter for Bastion security group | `string` | `"bastion-sg"` | None |
| `app_b_security_group_name` | Name filter for App B security group | `string` | `"app-b-sg"` | None |
| `bastion_instance_name_tag` | Tag:Name filter for Bastion EC2 | `string` | `"Bastion-Host"` | None |
| `app_b_instance_name_tag` | Tag:Name filter for App B EC2 | `string` | `"App-B-Instance"` | None |
| `peering_connection_id` | Optional explicit VPC peering ID | `string` | `""` | None |
| `default_tags` | Default tags map | `map(string)` | See `variables.tf` | None |

### Discovered Outputs

| Output | Description |
|---|---|
| `vpc_a_id` | Discovered AWS ID for VPC A |
| `vpc_a_cidr` | CIDR block confirmed for VPC A |
| `vpc_b_id` | Discovered AWS ID for VPC B |
| `vpc_b_cidr` | CIDR block confirmed for VPC B |
| `vpc_peering_id` | Discovered VPC Peering Connection ID |
| `vpc_peering_status` | Status of the VPC peering connection (`active`) |
| `vpc_peering_requester_vpc_id` | Requester VPC ID in the peering relation |
| `vpc_peering_accepter_vpc_id` | Accepter VPC ID in the peering relation |
| `vpc_a_public_subnet_id` | Subnet ID for VPC A public tier |
| `vpc_b_private_subnet_id` | Subnet ID for VPC B private tier |
| `vpc_a_public_route_table_id` | Route Table ID associated with VPC A public subnet |
| `vpc_b_private_route_table_id` | Route Table ID associated with VPC B private subnet |
| `bastion_security_group_id` | Security Group ID for Bastion host |
| `app_b_security_group_id` | Security Group ID for App B host |
| `bastion_instance_id` | EC2 instance ID for Bastion node |
| `bastion_public_ip` | Public IPv4 assigned to the Bastion host |
| `bastion_private_ip` | Private IPv4 assigned to the Bastion host |
| `app_b_instance_id` | EC2 instance ID for App B node |
| `app_b_private_ip` | Private IPv4 assigned to App B node |

---

## Execution Guide (Discovery Mode)

### Step 1: Initialize Terraform
```bash
terraform init
```

### Step 2: Format and Validate
```bash
terraform fmt -check
terraform validate
```

### Step 3: Discover Resources
Ensure AWS authentication is configured:
```bash
export AWS_REGION="eu-north-1"
# Optionally copy terraform.tfvars.example to terraform.tfvars to adjust tag names
terraform plan
```
If existing resources match the filters, `terraform plan` will display `0 to add, 0 to change, 0 to destroy` and populate all outputs.

### Step 4: Inspect Outputs
```bash
terraform apply -refresh-only
terraform output
```

---

## Security Best Practices
- **No Stored Secrets**: Never commit `.tfvars`, `.tfstate`, or `.pem` files.
- **Immutable Locks**: `.terraform.lock.hcl` is committed to guarantee deterministic provider versions across CI/CD and developer environments.
- **Read-Only Privilege**: For discovery mode, the executing IAM role requires only read permissions (`ec2:Describe*`).
