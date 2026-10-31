# Testing & Verification Protocol

## Overview & Verification Policy

In accordance with rigorous DevOps and Cloud Engineering standards:
- **No test is marked as PASSED without verifiable test evidence**.
- Configurations verified via static analysis and local syntax validation are explicitly distinguished from live runtime AWS connectivity tests.
- This document outlines the test cases, validation commands, and execution tracking matrix.

---

## Verification Status Summary

| Test ID | Test Category | Target Component | Verification Method | Status | Evidence / Notes |
|---|---|---|---|---|---|
| **TC-01** | Architecture | CIDR Non-overlapping Design | Static Configuration Audit | **CONFIRMED** | `10.10.0.0/16` and `10.20.0.0/16` have zero CIDR overlap. |
| **TC-02** | Terraform | Code Formatting (`terraform fmt`) | Local CLI execution | **PASSED** | Code formatted cleanly across all `.tf` files. |
| **TC-03** | Terraform | Configuration Syntax & Schema | `terraform validate` | **PASSED** | Validated root and `iac-provisioning` configurations. |
| **TC-04** | Security | Inbound SSH Least Privilege | Code & Policy Audit | **CONFIRMED** | No `0.0.0.0/0` SSH access in production templates. |
| **TC-05** | Networking | VPC Peering Status (`pcx-xxxx`) | AWS Console / AWS CLI | **PENDING LIVE VERIFICATION** | Awaiting live AWS credentials / session execution. |
| **TC-06** | Networking | Bidirectional Route Table Check | AWS Console / AWS CLI | **PENDING LIVE VERIFICATION** | Requires inspection of live AWS route tables. |
| **TC-07** | Compute | Bastion SSH Connectivity | Terminal SSH Connection | **PENDING LIVE VERIFICATION** | Previously timed out; requires live connection attempt. |
| **TC-08** | End-to-End | Private ICMP / SSH over Peering | Bastion Terminal Session | **PENDING LIVE VERIFICATION** | Requires active Bastion session to ping/curl App B. |

---

## Detailed Test Procedures

### Test Case 1: VPC CIDR Non-Overlap Audit
- **Objective**: Verify that VPC A and VPC B have mathematically distinct CIDRs to enable VPC Peering.
- **Evaluation**:
  - VPC A: `10.10.0.0/16` (Range: `10.10.0.0` - `10.10.255.255`)
  - VPC B: `10.20.0.0/16` (Range: `10.20.0.0` - `10.20.255.255`)
- **Result**: **PASS** (Disjoint address spaces).

---

### Test Case 2: Terraform Syntax & Validation
- **Objective**: Confirm Terraform configurations pass syntax, type checking, and schema validation.
- **Commands**:
  ```bash
  # Check formatting
  terraform fmt -recursive -check

  # Validate Root Discovery Module
  cd terraform
  terraform validate

  # Validate Standalone Provisioning Module
  cd ../terraform/iac-provisioning
  terraform validate
  ```
- **Result**: **PASS** (`Success! The configuration is valid.`).

---

### Test Case 3: VPC Peering Status Verification
- **Objective**: Verify that the VPC Peering connection is in the `active` lifecycle state in AWS.
- **Command (AWS CLI)**:
  ```bash
  aws ec2 describe-vpc-peering-connections \
    --region eu-north-1 \
    --filters "Name=status-code,Values=active" \
    --query "VpcPeeringConnections[*].{ID:VpcPeeringConnectionId,Requester:RequesterVpcInfo.VpcId,Accepter:AccepterVpcInfo.VpcId,Status:Status.Code}" \
    --output table
  ```
- **Expected Result**: Single peering connection with Status = `active`.

---

### Test Case 4: Route Table Inspection
- **Objective**: Verify bidirectional routes pointing to the peering connection ID (`pcx-xxxx`).
- **Command (AWS CLI)**:
  ```bash
  # Check VPC A Route Table:
  aws ec2 describe-route-tables \
    --region eu-north-1 \
    --filters "Name=tag:Name,Values=VPC-A-Public-Route-Table" \
    --query "RouteTables[*].Routes[?VpcPeeringConnectionId!=null]"

  # Check VPC B Route Table:
  aws ec2 describe-route-tables \
    --region eu-north-1 \
    --filters "Name=tag:Name,Values=VPC-B-Private-Route-Table" \
    --query "RouteTables[*].Routes[?VpcPeeringConnectionId!=null]"
  ```
- **Expected Result**:
  - VPC A table contains destination `10.20.0.0/16` target `pcx-xxxx`.
  - VPC B table contains destination `10.10.0.0/16` target `pcx-xxxx`.

---

### Test Case 5: Bastion Host SSH Verification
- **Objective**: Connect to the public Bastion host from the authorized administrative workstation.
- **Command**:
  ```bash
  # Step 1: Ensure private key permissions
  chmod 400 my-key.pem

  # Step 2: Test SSH connection with verbose output
  ssh -v -i my-key.pem ec2-user@<BASTION_PUBLIC_IP>
  ```
- **Expected Result**: Successful interactive bash prompt: `[ec2-user@ip-10-10-1-10 ~]$`.

---

### Test Case 6: Cross-VPC Private Connectivity (ICMP Ping)
- **Objective**: Validate private network packet forwarding across the VPC Peering connection.
- **Command** (Executed from within the Bastion SSH session):
  ```bash
  ping -c 4 10.20.1.24
  ```
- **Expected Result**:
  ```text
  4 packets transmitted, 4 received, 0% packet loss, time 3004ms
  rtt min/avg/max/mdev = 0.421/0.512/0.603/0.071 ms
  ```

---

### Test Case 7: End-to-End SSH ProxyJump Access
- **Objective**: Connect directly from the local workstation to the private instance in VPC B without storing credentials on the Bastion.
- **Command**:
  ```bash
  ssh -J ec2-user@<BASTION_PUBLIC_IP> -i my-key.pem ec2-user@10.20.1.24
  ```
- **Expected Result**: Interactive shell session on `[ec2-user@ip-10-20-1-24 ~]$`.

---

## Live Execution Test Log

Use this table to record actual results when executing live tests against an AWS deployment:

| Timestamp (UTC) | Test Case | Executed Command | Observed Output | Verdict | Engineer |
|---|---|---|---|---|---|
| *Pending* | TC-05 | `aws ec2 describe-vpc-peering-connections` | | PENDING | |
| *Pending* | TC-06 | `aws ec2 describe-route-tables` | | PENDING | |
| *Pending* | TC-07 | `ssh -i key.pem ec2-user@<IP>` | | PENDING | |
| *Pending* | TC-08 | `ping -c 4 10.20.1.24` | | PENDING | |
