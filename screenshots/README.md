# AWS Console Evidence & Screenshots Guide

This directory is designated for storing visual verification evidence captured directly from the AWS Management Console and administrative terminal sessions.

> **Integrity Notice**:
> In accordance with production engineering standards, placeholder images or simulated screenshots are strictly forbidden. Upload actual screenshots when reproducing or validating this laboratory environment.

---

## Required Screenshot Checklist

When verifying your deployment in the AWS Console, capture and save the following screenshots using the exact filenames listed below:

| File Name | AWS Console View / Path | What It Verifies |
|---|---|---|
| `01-vpcs-overview.png` | **VPC Console** > Your VPCs (`eu-north-1`) | Shows both `VPC-A` (`10.10.0.0/16`) and `VPC-B` (`10.20.0.0/16`) in `Available` state. |
| `02-subnets-overview.png` | **VPC Console** > Subnets | Confirms `VPC-A-Public-Subnet` (`10.10.1.0/24`) and `VPC-B-Private-Subnet` (`10.20.1.0/24`). |
| `03-peering-connection.png` | **VPC Console** > Peering Connections | Shows the active peering connection (`pcx-xxxx`) between Requester (`VPC-A`) and Accepter (`VPC-B`) with status `Active`. |
| `04-route-table-vpc-a.png` | **VPC Console** > Route Tables > `VPC-A-Public-RT` > Routes tab | Confirms two target routes: `0.0.0.0/0` -> `igw-xxxx` and `10.20.0.0/16` -> `pcx-xxxx`. |
| `05-route-table-vpc-b.png` | **VPC Console** > Route Tables > `VPC-B-Private-RT` > Routes tab | Confirms the peering route: `10.10.0.0/16` -> `pcx-xxxx` with NO internet route. |
| `06-security-group-bastion.png` | **EC2 Console** > Security Groups > `bastion-sg` > Inbound Rules | Shows SSH (TCP 22) allowed strictly from your administrator workstation IP `/32`. |
| `07-security-group-app-b.png` | **EC2 Console** > Security Groups > `app-b-sg` > Inbound Rules | Shows SSH (TCP 22) restricted to `bastion-sg` and ICMP restricted to `10.10.0.0/16`. |
| `08-ec2-instances.png` | **EC2 Console** > Instances (`eu-north-1`) | Shows `Bastion-Host` (with Public IP) and `App-B-Instance` (Private IP only) in `running` state. |
| `09-terminal-bastion-ssh.png` | **Local Terminal** | Successful SSH session output connecting from your local machine to `Bastion-Host`. |
| `10-terminal-peering-ping.png` | **Bastion SSH Session** | Successful ICMP `ping -c 4 10.20.1.24` demonstrating end-to-end packet transmission across VPC Peering. |
| `11-terminal-app-b-ssh.png` | **Bastion or Local Terminal** | Successful SSH connection to `10.20.1.24` via Bastion jump host. |

---

## Instructions for Capturing Evidence

1. **Resolution & Crop**:
   - Capture high-resolution window screenshots (`1920x1080` or higher).
   - Ensure the AWS Region dropdown (`Stockholm` / `eu-north-1`) is visible in the top navigation bar.
2. **Redaction**:
   - Mask sensitive 12-digit AWS Account IDs before committing to a public GitHub repository.
   - Do NOT obscure internal RFC 1918 private IPs (`10.10.x.x`, `10.20.x.x`) as they demonstrate architectural correctness.
3. **Commit Process**:
   - Place image files directly inside this `screenshots/` directory.
   - Stage and commit with descriptive messages:
     ```bash
     git add screenshots/01-vpcs-overview.png screenshots/03-peering-connection.png
     git commit -m "docs: add console verification screenshots for VPCs and Peering"
     ```
