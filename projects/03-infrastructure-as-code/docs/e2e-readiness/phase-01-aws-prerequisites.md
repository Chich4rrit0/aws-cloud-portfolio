# E2E Readiness — Phase 01: AWS prerequisites

**Mode:** read-only verification; no AWS resources created, updated or deleted.

## Verified on 2026-09-11

- The AWS-managed CloudFront origin-facing prefix list is available in `us-east-1` and is in a ready state. Its runtime ID must be supplied only during an approved Terraform run; it is not hardcoded in the repository.
- PostgreSQL engine version `18.3` is available in `us-east-1`.
- Project 01 remains active with its own ALB, private artifact/frontend buckets and deployed CloudFront distribution. Project 03 will remain isolated by naming and resources.

## Remaining deployment prerequisites

1. Generate the application database password locally, create the application role/schema through an approved temporary bootstrap path, and store only its value in a standard SSM SecureString.
2. Package and publish the approved API ZIP and private frontend files before Compute begins serving traffic.
3. Protect the local Terraform state: it can retain sensitive input values even when the CLI redacts them. Keep it outside Git and remove it only after approved teardown verification.
4. Perform a new Cost Check immediately before deployment and agree on same-day teardown timing.

## Decision

The E2E design remains viable. The next phase is local readiness implementation, not deployment.
