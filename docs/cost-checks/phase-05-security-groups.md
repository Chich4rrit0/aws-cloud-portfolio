# Cost Check — Phase 5: Security Groups

**Scope:** Three VPC Security Groups and ingress/egress rules.

## Resources created

- `portfolio-p01-sg-alb`
- `portfolio-p01-sg-app`
- `portfolio-p01-sg-db`

## Resources that generate cost

- No direct hourly charge is expected for Security Groups themselves.
- No ALB, EC2, RDS, NAT Gateway, Elastic IP, or data-producing workload exists yet.

## Resources that can be stopped or deleted

- Security Groups are configuration objects and cannot be stopped.
- Delete them only after dependent resources are detached or removed. Deletion is destructive and requires explicit approval.

## Unexpected-cost risk

- The temporary future ALB rule allows public HTTP, but no ALB exists yet, so it cannot receive traffic.
- When EC2 instances are introduced, App egress over HTTP/HTTPS and internet data transfer must be monitored.
- AWS billing data can be delayed; the existing Budget alert remains the cost-notification control.
