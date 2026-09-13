# E2E Readiness — Phase 08: executable database bootstrap

## Scope

`scripts/e2e/Initialize-Project03E2eDatabase.ps1` implements the temporary
database-bootstrap pattern defined in Phase 04. It is safe by default: without
`-Execute` it prints an execution summary and calls no AWS API.

## Controlled execution model

When explicitly approved in a future checkpoint, the script receives only
non-secret Foundation outputs as arguments. It prompts locally for the RDS
master password, creates a short-lived SecureString parameter, and launches a
temporary Amazon Linux EC2 instance in an E2E public application subnet.

The instance has no SSH key and no inbound administration rule. Its security
group permits only PostgreSQL to the isolated E2E RDS security group and HTTPS
egress for Session Manager and Parameter Store. The script creates a matching
temporary RDS ingress rule for PostgreSQL from that bootstrap group, then
revokes the rule during cleanup. Its narrowly-scoped IAM role
can read/delete the temporary master parameter and write only the application
password parameter.

The remote Session Manager command installs a PostgreSQL client, creates or
updates `taskmanager_app`, grants the minimal database/schema access required
by the Project 01 backend, writes its generated password to the runtime
parameter, and deletes the temporary master parameter. It never requests or
prints secret command output.

## Cleanup and failure behavior

On success, the script terminates its bootstrap instance and removes the
temporary security group, role, instance profile, and master parameter. The
application password remains because Runtime needs it. On failure it applies
the same cleanup by default; `-RetainOnFailure` is an explicit diagnostic
exception and must be followed by a manual cleanup review.

Cleanup tracks the identifiers created by its own execution. A collision with
an existing resource therefore fails safely without deleting a resource that
pre-dated the execution.

## Deliberate boundary

The script has been added and will be locally syntax-checked and dry-run
validated only. It has not been invoked with `-Execute`; therefore no EC2,
IAM, SSM, RDS, or other AWS resources have been changed.
