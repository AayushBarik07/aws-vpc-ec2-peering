# Implementation Guide — AWS VPC Peering

## Project Overview

This guide details the step-by-step implementation of an enterprise-grade VPC Peering architecture between two isolated Virtual Private Clouds in the AWS `eu-north-1` (Stockholm) region.

---

## Technical Specifications

| Parameter | VPC A (Requester / Edge) | VPC B (Accepter / Private App) |
|---|---|---|
| **VPC Name** | `VPC-A` | `VPC-B` |
| **IPv4 CIDR** | `10.10.0.0/16` | `10.20.0.0/16` |
| **Subnet Name** | `VPC-A-Public-Subnet` | `VPC-B-Private-Subnet` |
| **Subnet CIDR** | `10.10.1.0/24` | `10.20.1.0/24` |
| **Subnet Type** | Public (`map_public_ip_on_launch = true`) | Private (`map_public_ip_on_launch = false`) |
| **Internet Gateway** | Attached (`VPC-A-IGW`) | None |
| **Security Group** | `bastion-sg` | `app-b-sg` |
| **EC2 Instance** | `Bastion-Host` (`10.10.1.10`) | `App-B-Instance` (`10.20.1.24`) |
| **Instance Type** | `t3.micro` | `t3.micro` |
| **Operating System**| Amazon Linux 2023 | Amazon Linux 2023 |

---

## Implementation Workflow

### Stage 1: Create VPCs and Subnets

1. **Provision VPC A**:
   - Name: `VPC-A`
   - CIDR: `10.10.0.0/16`
   - Tenancy: Default
   - Enable DNS Hostnames: `true`
   - Enable DNS Resolution: `true`

2. **Provision VPC A Public Subnet**:
   - Subnet Name: `VPC-A-Public-Subnet`
   - VPC: `VPC-A`
   - CIDR Block: `10.10.1.0/24`
   - Availability Zone: `eu-north-1a`
   - Setting: Enable auto-assign public IPv4 address.

3. **Provision VPC B**:
   - Name: `VPC-B`
   - CIDR: `10.20.0.0/16`
   - Tenancy: Default
   - Enable DNS Hostnames: `true`
   - Enable DNS Resolution: `true`

4. **Provision VPC B Private Subnet**:
   - Subnet Name: `VPC-B-Private-Subnet`
   - VPC: `VPC-B`
   - CIDR Block: `10.20.1.0/24`
   - Availability Zone: `eu-north-1a`
   - Setting: Disable auto-assign public IPv4 address.

---

### Stage 2: Internet Connectivity for VPC A

1. **Create Internet Gateway**:
   - Name tag: `VPC-A-IGW`.
2. **Attach to VPC A**:
   - Attach `VPC-A-IGW` to `VPC-A`.
   - *Note*: An Internet Gateway is attached solely to VPC A. VPC B remains completely decoupled from public internet ingress and egress.

---

### Stage 3: Establish the VPC Peering Connection

1. **Initiate Peering Request**:
   - Name: `VPC-A-to-VPC-B-Peering`
   - Requester VPC: Select `VPC-A` (`10.10.0.0/16`)
   - Region: This region (`eu-north-1`)
   - Accepter VPC: Select `VPC-B` (`10.20.0.0/16`)
2. **Accept Peering Connection**:
   - In AWS Console, select the created peering connection (`pcx-xxxx`).
   - Choose **Actions > Accept Request**.
   - Confirm status transitions from `Pending-Acceptance` to `Active`.

---

### Stage 4: Configure Routing Tables

#### 1. VPC A Public Route Table (`VPC-A-Public-RT`)
Create and associate with `VPC-A-Public-Subnet`:
- Route 1: `10.10.0.0/16` -> `local` (System default)
- Route 2: `0.0.0.0/0` -> `VPC-A-IGW` (Target: Internet Gateway)
- Route 3: `10.20.0.0/16` -> `pcx-xxxx` (Target: Peering Connection)

#### 2. VPC B Private Route Table (`VPC-B-Private-RT`)
Create and associate with `VPC-B-Private-Subnet`:
- Route 1: `10.20.0.0/16` -> `local` (System default)
- Route 2: `10.10.0.0/16` -> `pcx-xxxx` (Target: Peering Connection)
- *Do NOT add any route for `0.0.0.0/0`.*

---

### Stage 5: Security Group Provisioning

#### 1. Bastion Security Group (`bastion-sg`)
Create in `VPC-A`:
- **Inbound Rule**:
  - Type: `SSH`
  - Protocol: `TCP`
  - Port: `22`
  - Source: `<YOUR_ADMIN_IP>/32` (Must NOT be `0.0.0.0/0`)
  - Description: "Administrative SSH access"
- **Outbound Rule**:
  - All traffic to `0.0.0.0/0` (for updates and relaying).

#### 2. App B Security Group (`app-b-sg`)
Create in `VPC-B`:
- **Inbound Rule 1**:
  - Type: `SSH`
  - Protocol: `TCP`
  - Port: `22`
  - Source: Select `bastion-sg` (by Security Group ID) or specify `10.10.1.0/24`.
  - Description: "SSH ingress from Bastion Host"
- **Inbound Rule 2**:
  - Type: `Custom ICMP - IPv4`
  - Protocol: `ICMP`
  - Port Range: `Echo Request`
  - Source: `10.10.0.0/16`
  - Description: "ICMP diagnostic ping from VPC A"
- **Outbound Rule**:
  - All traffic to `10.10.0.0/16` (or stateful automatic response).

---

### Stage 6: Launch EC2 Compute Nodes

1. **Launch Bastion Host**:
   - Name: `Bastion-Host`
   - Subnet: `VPC-A-Public-Subnet`
   - AMI: Amazon Linux 2023 (`al2023-ami-2023.*-x86_64`)
   - Instance Type: `t3.micro`
   - Auto-assign Public IP: `Enable`
   - Security Group: Attach `bastion-sg`
   - Key Pair: Select your managed `.pem` key pair

2. **Launch Private App Server**:
   - Name: `App-B-Instance`
   - Subnet: `VPC-B-Private-Subnet`
   - AMI: Amazon Linux 2023 (`al2023-ami-2023.*-x86_64`)
   - Instance Type: `t3.micro`
   - Auto-assign Public IP: `Disable`
   - Security Group: Attach `app-b-sg`
   - Key Pair: Select the same managed `.pem` key pair

---

## Infrastructure as Code (IaC) Integration

The repository offers two distinct methods to operate with Terraform:

### Method A: Discovery & Audit Mode (Root `/terraform`)
Use when AWS resources have been manually configured or pre-exist.
```bash
cd terraform
terraform init
terraform plan
terraform output
```
This inspects the active infrastructure and populates all resource identifiers without mutating AWS state.

### Method B: Automated Provisioning (`/terraform/iac-provisioning`)
Use when provisioning the infrastructure from scratch into an empty AWS environment.
```bash
cd terraform/iac-provisioning
cp terraform.tfvars.example terraform.tfvars
# Update admin_ssh_cidr and ssh_key_name
terraform init
terraform apply
```
