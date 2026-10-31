# Architectural Specification — AWS VPC Peering

## Executive Summary

This document details the architectural design for private cross-network connectivity between two isolated Amazon Web Services (AWS) Virtual Private Clouds (VPCs) in the `eu-north-1` (Stockholm) region. 

The architecture implements a secure **Bastion Host (Jump Host)** topology in **VPC A** to administer an isolated, private workload residing in **VPC B** over a high-performance, point-to-point **VPC Peering Connection**.

---

## 1. Network Topology & CIDR Allocation

A foundational requirement for VPC Peering is that the peering VPCs must possess non-overlapping IPv4 CIDR blocks.

```mermaid
flowchart LR
    subgraph Region["AWS Region: eu-north-1"]
        subgraph VPCA["VPC A (Requester) — 10.10.0.0/16"]
            SubnetA["Public Subnet: 10.10.1.0/24<br/>• Bastion Host (10.10.1.10)<br/>• Usable IPs: 251"]
        end

        subgraph Peering["Direct AWS Backbone"]
            PCX["VPC Peering Connection<br/>(pcx-xxxx)"]
        end

        subgraph VPCB["VPC B (Accepter) — 10.20.0.0/16"]
            SubnetB["Private Subnet: 10.20.1.0/24<br/>• App Server (10.20.1.24)<br/>• Usable IPs: 251"]
        end
    end

    SubnetA <===>|"Non-transitive Peering"| PCX
    PCX <===>|"Direct Routing"| SubnetB

    classDef vpc fill:#f1f5f9,stroke:#0ea5e9,stroke-width:2px,color:#0f172a;
    classDef pcx fill:#fef3c7,stroke:#f59e0b,stroke-width:2px,color:#78350f;
    class VPCA,VPCB vpc;
    class PCX pcx;
```

### CIDR Subnetting Matrix

| Network Entity | IPv4 CIDR | Netmask | Total Addresses | Usable AWS Addresses | Function / Workload |
|---|---|---|---|---|---|
| **VPC A** | `10.10.0.0/16` | `255.255.0.0` | 65,536 | 65,531 | Ingress & Administration VPC |
| **VPC A Public Subnet** | `10.10.1.0/24` | `255.255.255.0` | 256 | 251 | Bastion Jump Host (`10.10.1.10`) |
| **VPC B** | `10.20.0.0/16` | `255.255.0.0` | 65,536 | 65,531 | Private Application Workload VPC |
| **VPC B Private Subnet**| `10.20.1.0/24` | `255.255.255.0` | 256 | 251 | Private Target Instance (`10.20.1.24`) |

> **AWS Subnet IP Reservations**: In any `/24` AWS subnet (256 addresses), AWS reserves 5 IP addresses:
> - `x.x.x.0`: Network address.
> - `x.x.x.1`: Reserved by AWS for the VPC router.
> - `x.x.x.2`: Reserved by AWS for DNS (AmazonProvidedDNS).
> - `x.x.x.3`: Reserved by AWS for future use.
> - `x.x.x.255`: Network broadcast address (not supported in AWS VPC, but reserved).

---

## 2. VPC Peering Mechanics

### Physical & Logical Transport
VPC Peering does not rely on physical cables, dedicated hardware routers, VPN tunnels, or NAT gateways. Instead, AWS maps VPC peering connections onto its Software-Defined Network (SDN) virtualization layer (AWS Hyperplane / Nitro network virtualization).

- **Encryption & Isolation**: Traffic travels entirely within the private AWS global network infrastructure. Traffic is never exposed to the public internet and cannot be intercepted by third-party AWS tenants.
- **No Gateway Bottleneck**: Unlike NAT Gateways, Virtual Private Gateways (VGW), or internet proxies, a VPC Peering connection has no single physical point of congestion or aggregate bandwidth choke. It supports the maximum throughput allowed by the attached EC2 network adapters (ENA).
- **MTU Limits**: Intra-region VPC peering supports standard Ethernet frames (1500 bytes) and Jumbo Frames (9001 bytes).

### The Non-Transitive Peering Rule
A fundamental networking constraint enforced by AWS is that **VPC Peering is strictly non-transitive**:
- If VPC A is peered with VPC B, and VPC B is peered with VPC C, **VPC A cannot reach VPC C** through VPC B.
- Similarly, an Internet Gateway attached to VPC A cannot be used as an edge router for VPC B. Traffic from VPC B targeting the internet (`0.0.0.0/0`) cannot traverse the peering link to exit via VPC A's Internet Gateway. If VPC B requires internet access, it must be provisioned with its own NAT Gateway in a public subnet or use VPC Endpoints.

---

## 3. Route Table Routing Architecture

Routing in an AWS VPC is governed by route tables associated with individual subnets. For traffic to flow across a peering connection, both VPCs must have explicit route table entries pointing to the peering connection ID (`pcx-xxxx`).

### VPC A Public Route Table (`VPC-A-Public-RT`)

Associated Subnet: `VPC-A-Public-Subnet` (`10.10.1.0/24`)

| Destination CIDR | Target | Purpose | Status |
|---|---|---|---|
| `10.10.0.0/16` | `local` | Internal VPC A routing | Active (System Default) |
| `0.0.0.0/0` | `igw-xxxx` | Ingress SSH administration and outbound updates | Active |
| `10.20.0.0/16` | `pcx-xxxx` | Cross-VPC traffic destined for VPC B | Active |

### VPC B Private Route Table (`VPC-B-Private-RT`)

Associated Subnet: `VPC-B-Private-Subnet` (`10.20.1.0/24`)

| Destination CIDR | Target | Purpose | Status |
|---|---|---|---|
| `10.20.0.0/16` | `local` | Internal VPC B routing | Active (System Default) |
| `10.10.0.0/16` | `pcx-xxxx` | Return traffic and cross-VPC communication with VPC A | Active |

> **Critical Routing Principle**: AWS VPC routing operates on the **Longest Prefix Match (LPM)** rule. When Bastion sends a packet to `10.20.1.24`, the route table evaluates `10.20.0.0/16` (`/16`) versus `0.0.0.0/0` (`/0`). Because `/16` is more specific than `/0`, the packet is routed over `pcx-xxxx` rather than through the internet gateway.

---

## 4. Security Group Ingress / Egress Architecture

Security Groups act as stateful virtual firewalls operating at the Elastic Network Interface (ENI) level.

```mermaid
flowchart TD
    Admin["Admin Workstation"] -->|"Inbound TCP 22<br/>(Admin IP /32 only)"| BastionSG["bastion-sg (VPC A)<br/>• Inbound: TCP 22 (Admin IP)<br/>• Outbound: TCP 22 to VPC B CIDR"]
    BastionSG -->|"VPC Peering (pcx-xxxx)<br/>Direct AWS Backbone"| AppSG["app-b-sg (VPC B)<br/>• Inbound: TCP 22 from bastion-sg ID<br/>• Inbound: ICMP Echo from 10.10.0.0/16<br/>• Outbound: VPC A CIDR"]

    classDef sg fill:#f8fafc,stroke:#2563eb,stroke-width:2px,color:#0f172a;
    class BastionSG,AppSG sg;
```

### Bastion Security Group (`bastion-sg`)
- **Inbound**:
  - `TCP 22` (SSH): Authorized Admin Workstation IP (`<admin_ip>/32`).
- **Outbound**:
  - `TCP 22` (SSH): Allowed to `10.20.1.0/24` (or `0.0.0.0/0`).
  - `TCP 80 / 443`: Allowed to internet for security patching (dnf/yum).
  - `ICMP Echo Request`: Allowed to `10.20.0.0/16` for diagnostics.

### Private App Security Group (`app-b-sg`)
- **Inbound**:
  - `TCP 22` (SSH): Restricted to `bastion-sg` security group reference (intra-region cross-VPC security group referencing is supported by AWS) or `10.10.1.0/24`.
  - `ICMP Type 8 Code 0` (Echo Request): Restricted to `10.10.0.0/16`.
- **Outbound**:
  - Stateful response traffic automatically allowed by AWS security group state tracking. Explicit rule permits outbound traffic back to `10.10.0.0/16`.

---

## 5. End-to-End Traffic Flow Sequences

### Sequence 1: Administrator SSH Connection to Bastion
```mermaid
sequenceDiagram
    autonumber
    actor Admin as Admin Workstation
    participant IGW as Internet Gateway (VPC A)
    participant SG_A as bastion-sg
    participant Bastion as Bastion Host (10.10.1.10)

    Admin->>IGW: TCP SYN (Port 22) -> Bastion Public IP
    IGW->>SG_A: Packet evaluated against Inbound Rules
    Note over SG_A: Match: Admin IP /32 allowed on port 22
    SG_A->>Bastion: Packet delivered to Bastion ENI
    Bastion-->>Admin: TCP SYN-ACK (Stateful connection established)
    Admin->>Bastion: SSH Handshake & Key Authentication
```

### Sequence 2: Jump Host Relaying to Private Workload (VPC B)
```mermaid
sequenceDiagram
    autonumber
    participant Bastion as Bastion Host (10.10.1.10)
    participant RT_A as VPC A Route Table
    participant PCX as VPC Peering Connection
    participant RT_B as VPC B Route Table
    participant SG_B as app-b-sg
    participant AppB as App B Server (10.20.1.24)

    Bastion->>RT_A: SSH / ICMP packet destined for 10.20.1.24
    RT_A->>PCX: Longest Prefix Match (10.20.0.0/16 -> pcx-xxxx)
    PCX->>RT_B: Packet traverses AWS SDN Backbone
    RT_B->>SG_B: Forwarded to VPC B Private Subnet
    Note over SG_B: Match: Source 10.10.1.10 matches bastion-sg/CIDR
    SG_B->>AppB: Delivered to private ENI
    AppB-->>Bastion: Response packet routed back via RT_B (10.10.0.0/16 -> pcx-xxxx)
```
