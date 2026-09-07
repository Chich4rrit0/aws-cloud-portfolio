# Cost Check — Phase 7: RDS development database

**Scope:** private PostgreSQL RDS database and its required DB subnet group and password parameter.

## Resources created

- `portfolio-p01-db-subnet-group`
- SecureString parameter `/portfolio/project-01/database/password`
- `portfolio-p01-postgres` RDS instance: PostgreSQL 18.3, `db.t3.micro`, Single-AZ, 20 GiB GP3

## Estimated cost

These are estimates, not billed amounts. They were checked through the AWS Pricing API for `us-east-1` on 2026-09-07:

- RDS PostgreSQL `db.t3.micro`, Single-AZ: US$0.018 per instance-hour.
- GP3 storage: US$0.115 per GB-month.
- 20 GiB storage: approximately US$2.30 per month.
- Baseline for 730 hours: approximately **US$15.44 per month** (US$13.14 compute plus US$2.30 storage).
- Baseline for one day: approximately **US$0.51**, excluding data transfer and other services.

The baseline does not include data transfer, backup storage beyond the included allocation, log ingestion, snapshots, or later ALB and EC2 resources. Credits may offset charges but are not a replacement for monitoring actual billed usage.

## Resources that generate cost

- The RDS instance begins compute billing when it becomes available.
- Provisioned RDS storage and backup-related storage can continue generating charges while the instance is stopped.

## Resources that can be stopped or deleted

- RDS may be stopped temporarily, but this is not a zero-cost state and AWS starts it again after at most seven days.
- The DB subnet group and SecureString parameter do not have an instance-hour charge, but should be removed after all dependent resources are removed.
- Deleting RDS is destructive and requires a separate explicit approval, including whether to take a final snapshot. A snapshot can generate storage charges.

## Unexpected-cost risk

- The US$15.44 monthly RDS baseline leaves little room below the project target of approximately US$17 before adding ALB, EC2, data transfer or logs.
- AWS Budgets sends alerts and billing data can be delayed; it is not an immediate technical shutoff.
- Initial review deadline: 2026-09-10. Do not extend the RDS runtime without reassessing cost and purpose.
