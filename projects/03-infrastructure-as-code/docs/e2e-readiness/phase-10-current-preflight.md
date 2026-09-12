# E2E Readiness — Phase 10: current read-only preflight

## Date and mode

Date: 2026-09-12. This was a read-only AWS CLI verification. No resource was
created, modified, uploaded, started, stopped, or deleted.

## Confirmed

- The configured temporary profile authenticated successfully in `us-east-1`.
- The account reports an active Free Plan with 171.82 USD in remaining credits
  and the existing `portfolio-zero-spend` budget is present at USD 1.00.
- The budget had USD 0.00 actual spend at query time; a blank forecast is not a
  prediction of zero future cost and billing data can be delayed.
- The isolated `10.30.0.0/16` CIDR is not currently assigned to a VPC.
- PostgreSQL engine version `18.3` is currently returned in `us-east-1`.
- There are no resources tagged `ProjectNumber=03` and `Environment=e2e`.

## Blocking observation — CloudFront prefix list

The current `describe-managed-prefix-lists` query, using the AWS-documented
`owner-id=AWS` filter, returned no discoverable entry named
`com.amazonaws.global.cloudfront.origin-facing`. The legacy prefix-list query
also returned no entry. Therefore no ID is available to populate Foundation's
required `cloudfront_origin_prefix_list_id` input.

This supersedes the earlier readiness note that described the list as verified.
The contradiction is preserved rather than hidden: the current, repeatable
preflight result is authoritative for an actual deployment.

## Decision

Foundation deployment remains blocked. Do not invent an ID and do not replace
the security-group source with `0.0.0.0/0` merely to proceed. First perform a
read-only console inspection of VPC **Managed prefix lists** in `us-east-1`
with owner **AWS**, then either resolve the discovery issue or explicitly
approve a reviewed alternative edge-security design.

## Reproducibility

Run `scripts/e2e/Test-Project03E2ePreflight.ps1` with the local AWS profile.
It performs the same checks and reports `OverallReady`; it never mutates AWS.
