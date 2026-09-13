# Project 03 E2E — Active Cost Check

**Status:** active laboratory environment as of 2026-09-13. This document
supersedes earlier plan-only statements for the current E2E run.

## Active resources

| Layer | Active components | Cost characteristic |
| --- | --- | --- |
| Data | Single-AZ RDS PostgreSQL, storage and backup retention | Recurring while the DB exists |
| Runtime | Public ALB, ASG desired capacity 1, one `t3.micro`, encrypted gp3 EBS | Recurring while Runtime remains deployed |
| Edge | CloudFront distribution with `PriceClass_100` | Usage-dependent requests and transfer |
| Storage | Two private S3 buckets and the release/frontend objects | Storage and request dependent |
| Operations | CloudWatch log group with seven-day retention and one alarm | Log ingestion/storage and metric use dependent |
| Secrets | Two E2E SSM SecureString parameters | Service use dependent |

There is no NAT Gateway, Elastic IP, Route 53 hosted zone, custom domain,
WAF, ECR repository or permanently scaled second EC2 instance in this E2E
environment.

## Cost controls currently in effect

- ASG is intentionally held at minimum/desired capacity **1** and maximum
  capacity **2**; no load test has been run.
- Logs retain seven days, and the alarm has no automated action.
- S3 blocks public access; the frontend bucket read policy is limited to the
  deployed CloudFront distribution.
- CloudFront uses the default domain and `PriceClass_100`.
- The account budget alert remains the authoritative alerting control. AWS
  billing data can be delayed, so it is not a real-time circuit breaker.

## Required cleanup decision

This environment now has recurring-cost resources. Do not leave it running
without a short, intentional validation window. The safe destructive order is:

1. Destroy Edge and wait until CloudFront deletion completes.
2. Destroy Runtime, which removes the ALB, ASG/EC2, listener rules, logs and
   runtime IAM policy.
3. Destroy Foundation only after preserving required evidence; this removes
   RDS, the VPC layer, buckets and remaining E2E parameters.

Each destroy stage requires a fresh explicit approval because it can remove
data and evidence. Before destruction, verify Cost Explorer/Budgets for actual
charges; this document intentionally does not claim current prices or charges.
