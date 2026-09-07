# Cost Check — Phase 4: Network Foundation

**Scope:** VPC, Internet Gateway, six subnets, three route tables, DNS attributes, and route-table associations.

## Resources created

- One VPC with CIDR `10.20.0.0/16`.
- One attached Internet Gateway.
- Six subnets across two Availability Zones.
- Three dedicated route tables and their subnet associations.

## Resources that generate cost

- No direct hourly charge is expected from the VPC, subnets, route tables, or attached Internet Gateway alone.
- No workload currently sends traffic through the IGW, so current network data-transfer usage should be zero.

## Resources deliberately not created

- NAT Gateway: avoided because AWS charges NAT Gateway-hours and data processing while it is provisioned.
- Elastic IP, EC2, RDS, ALB, CloudFront, S3, Route 53, and VPC endpoints.

## Resources that can be stopped or deleted

- Networking primitives cannot be meaningfully “stopped.” Their cleanup order is: dependent resources, subnet associations, subnets, route tables, IGW detach/delete, then VPC deletion.
- Deletion is destructive and requires a separate explicit approval.

## Unexpected-cost risk

- Future internet traffic through the Internet Gateway can incur applicable data-transfer charges.
- Creating a NAT Gateway later would introduce hourly and per-GB charges. Reassess the budget and obtain approval first.

Reference: [Amazon VPC pricing](https://aws.amazon.com/vpc/pricing/), consulted on 2026-09-06.
