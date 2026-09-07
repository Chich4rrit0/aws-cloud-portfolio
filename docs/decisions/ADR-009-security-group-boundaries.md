# ADR-009 — Security Group Boundaries

- **Status:** Accepted
- **Date:** 2026-09-07

## Context

Project 01 places the ALB, application instances, and PostgreSQL database in distinct network tiers. Security Groups provide the stateful, workload-level boundary between those tiers.

## Decision

Create three dedicated Security Groups and reference groups rather than fixed private IP addresses:

| Group | Inbound | Outbound |
| --- | --- | --- |
| `portfolio-p01-sg-alb` | TCP 80 from `0.0.0.0/0` temporarily | TCP 3000 to App SG only |
| `portfolio-p01-sg-app` | TCP 3000 from ALB SG only | TCP 5432 to DB SG; TCP 80/443 to Internet |
| `portfolio-p01-sg-db` | TCP 5432 from App SG only | No rules |

The default allow-all egress rule is revoked from every group. SSH is not allowed; EC2 administration will use Systems Manager Session Manager.

## Consequences

- A direct internet request cannot reach application instances or the database.
- The database is reachable only from instances carrying the App SG.
- App egress on ports 80/443 remains necessary in this no-NAT development topology for Systems Manager and package retrieval. It is broader than a production-private-subnet design and will be reconsidered with VPC endpoints or NAT in a later architecture iteration.
- The ALB public HTTP rule is deliberately temporary. After CloudFront is deployed, it will be replaced with an inbound rule scoped to the AWS-managed CloudFront origin-facing prefix list.
