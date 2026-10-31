# Standalone Infrastructure Provisioning (IaC)

This directory provides the complete Infrastructure-as-Code (IaC) definition to deploy the entire dual-VPC peering laboratory from scratch in any AWS account.

> **Note on Architecture Separation:**
> - The parent directory (`/terraform`) contains **Data Source Discovery / Audit** configurations that inspect manually configured or pre-existing AWS infrastructure without risking unintended mutations or resource replacement.
> - This directory (`/terraform/iac-provisioning`) contains **Resource Management** configurations to provision, configure, and manage the full lab lifecycle end-to-end.

---

## Resources Provisioned

1. **VPC A (Requester / Jump Host VPC)**:
   - CIDR: `10.10.0.0/16`
   - Public Subnet: `10.10.1.0/24` with automatic public IP assignment
   - Internet Gateway (`igw_a`) attached to VPC A
   - Public Route Table with `0.0.0.0/0` -> IGW and `10.20.0.0/16` -> Peering Connection
   - Bastion EC2 Instance (`t3.micro`, Amazon Linux 2023)
   - Bastion Security Group (`bastion-sg`) restricting SSH ingress to `admin_ssh_cidr`

2. **VPC B (Accepter / Private App VPC)**:
   - CIDR: `10.20.0.0/16`
   - Private Subnet: `10.20.1.0/24` (no public IP, no Internet Gateway)
   - Private Route Table with `10.10.0.0/16` -> Peering Connection
   - Private App EC2 Instance (`t3.micro`, Amazon Linux 2023)
   - App Security Group (`app-b-sg`) allowing SSH only from `bastion-sg` and ICMP only from VPC A

3. **VPC Peering Connection**:
   - Connection requester: VPC A
   - Connection accepter: VPC B
   - Auto-accept enabled (single-account deployment)

---

## Deployment Workflow

### 1. Prerequisites
- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) >= 1.6.0
- Configured AWS CLI credentials (`aws configure`) or environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`)
- An existing EC2 Key Pair in `eu-north-1` (or your chosen target region)

### 2. Configure Variables
Copy the example variables file:
```bash
cp terraform.tfvars.example terraform.tfvars
```
Edit `terraform.tfvars` and set:
- `admin_ssh_cidr`: Your current public IPv4 address with `/32` (e.g. `curl -s https://checkip.amazonaws.com` -> `203.0.113.10/32`)
- `ssh_key_name`: The name of your existing AWS Key Pair

### 3. Initialize and Validate
```bash
terraform init
terraform validate
```

### 4. Review Plan and Apply
```bash
terraform plan
terraform apply
```

### 5. Access and Verification
Once applied, Terraform outputs the connection helper strings:
```bash
# Connect to Bastion
ssh -i <your-key.pem> ec2-user@<bastion_public_ip>

# Connect directly to App B via SSH ProxyJump (-J)
ssh -J ec2-user@<bastion_public_ip> -i <your-key.pem> ec2-user@<app_b_private_ip>
```

### 6. Clean Up / Destroy
When lab exercises are complete:
```bash
terraform destroy
```
