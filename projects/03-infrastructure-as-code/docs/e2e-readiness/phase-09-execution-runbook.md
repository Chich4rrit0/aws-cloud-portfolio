# E2E Readiness — Phase 09: staged execution runbook

## Status and authority boundary

This is a future-run procedure, not an execution authorization. Every command
that calls `terraform apply`, runs an E2E script with `-Execute`, uploads to
S3, deletes an SSM parameter, empties a bucket, or runs `terraform destroy`
requires a current, explicit approval. Do not use `-auto-approve`.

The environment remains isolated as `portfolio-p03-e2e` in `us-east-1`. It
must not import, alter, reuse, or destroy Project 01 or Project 02 resources.

## Gate 0 — same-day preflight

Before the first mutation:

1. Re-check the active AWS identity, `us-east-1`, AWS Budget alert, current
   credits, prices, and all existing Project 01 resources.
2. Confirm a same-day teardown window. The budget is an early alert, not a
   kill switch.
3. Confirm that the isolated `10.30.0.0/16` CIDR does not overlap an existing
   VPC.
4. Re-read the Foundation, Runtime, Edge, bootstrap and publication plans.
5. Confirm there is no pre-existing resource using the E2E prefix or the two
   SSM parameter names.

## Stage 1 — Foundation

From `terraform/environments/e2e-foundation`, supply two currently verified
AZ names and the current CloudFront origin-facing prefix-list ID. Prompt for
the RDS master password locally, assign it only to the current PowerShell
process as `TF_VAR_database_master_password`, then clear that environment
variable in a `finally` block. Do not place it in `.tfvars`, a command line,
Git, or a persistent environment variable.

Run `terraform init`, inspect `terraform plan`, and only after a separate
approval run `terraform apply`. Save the non-secret `foundation` output in
memory for subsequent commands:

```powershell
$foundation = (& $terraformExe output -json foundation | ConvertFrom-Json)
```

Its explicit contract contains the VPC, subnet IDs, Security Group IDs,
instance profile, bucket names/ARNs, and RDS endpoint. Do not reconstruct
these values by guessing names or querying Project 01.

## Stage 2 — database bootstrap and artifact publication

After RDS is `available`, run the bootstrap script first in dry-run mode. At
an explicit execution approval, invoke it with Foundation's VPC, first public
application subnet, database Security Group, and endpoint. It will prompt for
the master password. Do not use `-RetainOnFailure` unless the diagnostic value
outweighs the cost/security risk and a cleanup owner is identified.

Confirm the application password SecureString exists by name only; never
request its decrypted value in the terminal.

Run `Publish-Project03E2eArtifacts.ps1` without `-Execute` to inspect its
release key. With a distinct explicit approval, run it with `-Execute` and the
Foundation artifact/frontend bucket names. Record its SHA-256 and object key;
do not copy Project 01 buckets or modify Project 01 source.

## Stage 3 — Runtime

From `terraform/environments/e2e-runtime`, pass only the Foundation contract
and the recorded artifact key through the current PowerShell process. Run
`init`, inspect `plan`, then obtain a separate approval for `apply`.

Expected checks after completion:

- the Auto Scaling Group has exactly one healthy instance;
- the ALB target group has one healthy target;
- the application responds to its health path through the ALB only from the
  approved CloudFront origin range once Edge is active;
- Session Manager access works without SSH;
- application logs reach the Project 03 CloudWatch log group;
- the dashboard and target-health alarm exist without triggering actions.

## Stage 4 — Edge

From `terraform/environments/e2e-edge`, generate the origin header in the
current PowerShell process and supply it as the sensitive Terraform variable.
Never put it in `.tfvars`, a command line, source file, or output. It is
stored as an E2E SecureString solely for controlled operations and will remain
in the local Terraform state until teardown.

Inspect the Edge plan before a separately approved apply. After CloudFront
finishes deploying, verify HTTPS frontend delivery, `/health`, and the CRUD
flow through `/api/*`. Test direct ALB access separately: it must not match
the listener rule without the private header. Remove test data before teardown.

## Stage 5 — teardown and evidence

Teardown is destructive and uses a new explicit confirmation. Verify evidence
and record final resource identifiers before beginning. Destroy in this order:

1. Edge (wait for CloudFront distribution deletion).
2. Runtime (ASG/instance, ALB, logs, dashboard and alarms).
3. Delete the application-password SecureString explicitly after Runtime no
   longer needs it.
4. Foundation (RDS, storage, security and network).

Foundation deletion will intentionally fail while S3 buckets contain the
published frontend/artifact objects. Empty only the two E2E buckets, after
explicitly confirming their names and that they are not Project 01 buckets,
then resume Foundation teardown. The development RDS configuration skips a
final snapshot, so its data is permanently discarded.

Finally, use read-only AWS queries to verify that no E2E-prefix resources,
application password parameter, EC2 instance, ALB, RDS, bucket, CloudFront
distribution, or local Terraform state remain. Delete local state files only
after that verification; their removal is also a destructive local action.
