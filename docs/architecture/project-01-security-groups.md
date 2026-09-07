# Project 01 — Implemented Security Groups

Security Groups are attached to the Project 01 VPC and use group-to-group references to avoid coupling rules to instance IP addresses.

## Effective rules

| Security Group | Purpose | Inbound | Outbound |
| --- | --- | --- | --- |
| `portfolio-p01-sg-alb` | Future ALB | HTTP 80 from Internet, temporarily | TCP 3000 to App SG |
| `portfolio-p01-sg-app` | Future EC2 / ASG instances | TCP 3000 from ALB SG | TCP 5432 to DB SG; TCP 80/443 to Internet |
| `portfolio-p01-sg-db` | Future RDS PostgreSQL | TCP 5432 from App SG | None |

## Explicitly excluded

- SSH port 22.
- Direct inbound access to App instances.
- Public inbound access to PostgreSQL.
- Default allow-all egress.

## Lifecycle

No compute or database resource is attached yet. Before deleting a Security Group later, delete or detach dependent ALB, EC2, and RDS resources first, then revoke dependent group references if needed. This is a destructive operation and requires explicit approval.
