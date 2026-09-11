# E2E Readiness — Phase 02: staged orchestration

## Finding

The current `terraform/environments/lab` root composes all seven modules. A single apply is unsuitable for the temporary E2E test: the EC2 bootstrap depends on a release object, an application database role and a SecureString that do not exist before Foundation resources are created.

Terraform `-target` is intentionally not the deployment workflow. It can bypass normal dependency behavior and would make the portfolio harder to reason about.

## Required E2E stages

1. **Foundation:** Network, Security, Data and Storage.
2. **Bootstrap and publication:** create the application database role, store its generated password in SSM, and upload the approved backend ZIP and frontend files.
3. **Runtime:** Compute and Operations; validate target health, Session Manager and logs.
4. **Edge:** CloudFront/OAC and origin guard; validate HTTPS, frontend and API paths.
5. **Same-day teardown:** reverse the approved stages after evidence collection.

## State handling

The staged roots will use local state only for this temporary exercise. State is sensitive: it must remain outside Git, be protected locally and be deleted only after teardown is verified. A remote state backend remains out of scope until separately approved.

## Decision

Do not run Terraform apply until staged E2E orchestration and the database bootstrap/publication procedure are implemented and validated locally.
