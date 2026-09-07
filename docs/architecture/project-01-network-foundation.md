# Project 01 — Network Foundation Implementation

## Implemented topology

The Project 01 VPC uses the approved CIDR `10.20.0.0/16` in `us-east-1`, split across `us-east-1a` and `us-east-1b`.

| Tier | Subnet | CIDR | AZ | Public IPv4 on launch | Route table behavior |
| --- | --- | --- | --- | --- | --- |
| Edge | `portfolio-p01-public-edge-a` | `10.20.0.0/24` | `us-east-1a` | Yes | Default route to IGW |
| Edge | `portfolio-p01-public-edge-b` | `10.20.1.0/24` | `us-east-1b` | Yes | Default route to IGW |
| App | `portfolio-p01-public-app-a` | `10.20.10.0/24` | `us-east-1a` | Yes | Default route to IGW |
| App | `portfolio-p01-public-app-b` | `10.20.11.0/24` | `us-east-1b` | Yes | Default route to IGW |
| DB | `portfolio-p01-private-db-a` | `10.20.20.0/24` | `us-east-1a` | No | Local route only |
| DB | `portfolio-p01-private-db-b` | `10.20.21.0/24` | `us-east-1b` | No | Local route only |

The VPC has DNS Support and DNS Hostnames enabled. The Internet Gateway is attached only to this VPC. No route from the DB subnets reaches the internet.

## Network controls intentionally absent

- No NAT Gateway.
- No Elastic IP.
- No EC2, RDS, ALB, CloudFront, S3 bucket, Route 53 zone, or VPC endpoint.
- No public database subnet or public RDS access.

Security groups are the next control layer. Although the app subnets are public to avoid a NAT Gateway during this portfolio phase, future EC2 instances will have no direct inbound access; the application security group will accept traffic only from the ALB security group.

## Reproducible scripts

`New-Project01Network.ps1` creates a fresh network and stops if it detects the named VPC. `Resume-Project01Network.ps1` is idempotent for a partially completed execution: it reuses tagged resources and only creates the missing network components.

Both scripts require `-Execute` to make AWS changes. Without that switch they are dry runs.
