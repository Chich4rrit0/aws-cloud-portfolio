# E2E Readiness — Phase 13: Foundation apply procedure

`Invoke-Project03E2eFoundationApply.ps1` performs the user-approved Foundation
apply only when invoked with `-Execute`. It prompts locally for the RDS master
password, sets temporary process-scoped Terraform inputs, runs `init` and
`validate`, then invokes `terraform apply` without `-auto-approve`.

Terraform must display the fresh plan and receive an interactive `yes` from
the operator. No secret, plan file, or long-lived environment variable is
created by the helper. On completion it clears all temporary environment
variables. Runtime, Edge, artifact publication, database bootstrap and every
destructive action remain separate gates.
