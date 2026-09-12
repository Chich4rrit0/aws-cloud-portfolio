# E2E Readiness — Phase 04: database bootstrap design

## Selected pattern

Use a dedicated, temporary `portfolio-p03-e2e-db-bootstrap` EC2 instance operated only through Session Manager. It has no SSH key, inbound administration rule or public business endpoint. Its lifecycle ends immediately after validation.

## Secret flow

1. The operator provides the RDS master password locally at execution time.
2. A temporary master `SecureString` is created only for bootstrap access.
3. The bootstrap instance retrieves it, creates/updates `taskmanager_app`, then generates the application password.
4. It writes only the application password to `/portfolio/project-03-e2e/database/password`.
5. The temporary master parameter, bootstrap EC2, role and instance profile are removed after validation.

No secret is written to Terraform source, `.tfvars`, Git, CloudFormation parameters, user data, command output or documentation.

## Required controls

- Bootstrap IAM role: SSM core, read only the temporary master parameter and write only the application password parameter.
- Bootstrap security group: PostgreSQL egress only to the isolated E2E RDS SG plus HTTPS required for SSM/AWS services.
- RDS must be available, private and reachable before the command is run.
- The actual mutation script must require `-Execute`; dry run is the default.

## Follow-up

Implement the dry-run-first bootstrap/publication scripts, then review them locally before requesting authorization to run any E2E Foundation deployment.
