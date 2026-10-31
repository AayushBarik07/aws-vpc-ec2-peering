# Architecture Design & Diagrams

This directory contains the system architecture designs, network topology models, and visual source files for the **AWS VPC Peering — Private Network Connectivity** project.

---

## Architecture Diagram Source

The diagram below is rendered from the source file [`vpc_peering_architecture.mmd`](vpc_peering_architecture.mmd) using GitHub Flavored Markdown Mermaid syntax.

```mermaid
flowchart TB
    subgraph Client["Administrator Environment"]
        AdminWorkstation["Admin Workstation\n(Admin IP /32)"]
    end

    subgraph Internet["Public Internet"]
        IGW["Internet Gateway\n(igw-xxxx)"]
    end

    subgraph Region["AWS Region: eu-north-1"]
        subgraph VPCA["VPC A (Requester) — 10.10.0.0/16"]
            subgraph VPCA_Public["Public Subnet — 10.10.1.0/24"]
                Bastion["EC2 Bastion Host\nPrivate: 10.10.1.10\nPublic: <Elastic/Public IP>\nt3.micro (Amazon Linux 2023)"]
                BastionSG["Security Group: bastion-sg\nInbound: TCP 22 from Admin IP\nOutbound: All traffic"]
            end
            VPCA_RT["Public Route Table\n0.0.0.0/0 -> IGW\n10.20.0.0/16 -> PCX"]
        end

        subgraph Peering["AWS VPC Peering Connection"]
            PCX["VPC Peering: pcx-xxxx\nStatus: Active\nNon-overlapping CIDRs\nDirect AWS Backbone Routing"]
        end

        subgraph VPCB["VPC B (Accepter) — 10.20.0.0/16"]
            subgraph VPCB_Private["Private Subnet — 10.20.1.0/24"]
                AppB["EC2 App Server\nPrivate: 10.20.1.24\nPublic: None\nt3.micro (Amazon Linux 2023)"]
                AppBSG["Security Group: app-b-sg\nInbound: TCP 22 from bastion-sg\nInbound: ICMP Echo from 10.10.0.0/16\nOutbound: VPC A CIDR"]
            end
            VPCB_RT["Private Route Table\n10.10.0.0/16 -> PCX\n(No 0.0.0.0/0 Route)"]
        end
    end

    AdminWorkstation -->|"1. SSH (Port 22) via Public IP"| IGW
    IGW --> VPCA_Public
    VPCA_Public -.-> BastionSG
    BastionSG -.-> Bastion
    Bastion -->|"2. Private Routing (10.20.0.0/16)"| VPCA_RT
    VPCA_RT --> PCX
    PCX --> VPCB_RT
    VPCB_RT --> VPCB_Private
    VPCB_Private -.-> AppBSG
    AppBSG -.-> AppB

    classDef public fill:#e1f5fe,stroke:#0288d1,stroke-width:2px,color:#01579b;
    classDef private fill:#e8f5e9,stroke:#388e3c,stroke-width:2px,color:#1b5e20;
    classDef peering fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#e65100;
    classDef compute fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#4a148c;

    class VPCA_Public,IGW public;
    class VPCB_Private private;
    class PCX,VPCA_RT,VPCB_RT peering;
    class Bastion,AppB compute;
```

---

## Network Component Specifications

### 1. VPC A (Requester / Edge Access Tier)
- **Role**: Ingestion and bastion jump host layer.
- **CIDR**: `10.10.0.0/16` (65,536 addresses).
- **Subnet**: Public Subnet `10.10.1.0/24` (251 usable IP addresses in AWS).
- **Public IP Allocation**: Enabled (`map_public_ip_on_launch = true`) or associated with an Elastic IP.
- **Routing**: Dual target table:
  - `0.0.0.0/0` directs outbound and inbound administrative internet traffic through the Internet Gateway (`igw-xxxx`).
  - `10.20.0.0/16` routes internal cross-VPC traffic over the peering connection (`pcx-xxxx`).

### 2. VPC B (Accepter / Private Application Tier)
- **Role**: Isolated workload and database tier.
- **CIDR**: `10.20.0.0/16` (65,536 addresses, non-overlapping with VPC A).
- **Subnet**: Private Subnet `10.20.1.0/24`.
- **Public IP Allocation**: Disabled (`map_public_ip_on_launch = false`). Instances in this subnet have no public IPv4 addresses and no default gateway to the internet.
- **Routing**: Single target table:
  - `10.10.0.0/16` directs reply and ingress traffic back to VPC A via the peering connection (`pcx-xxxx`).
  - No internet route (`0.0.0.0/0`) exists, ensuring zero internet exposure.

### 3. VPC Peering Connection (`pcx-xxxx`)
- **Type**: Intra-region VPC Peering in `eu-north-1` (Stockholm).
- **Transport**: AWS Global Private Network Backbone (traffic does not traverse the public internet, experience NAT bottlenecks, or require VPN termination).
- **Bandwidth**: Full AWS network interface bandwidth with no single point of failure or gateway bottleneck.
- **Transitive Routing Restriction**: VPC Peering is strictly non-transitive. Traffic cannot pass through VPC B to reach a third VPC or on-premises network without explicit peering.
