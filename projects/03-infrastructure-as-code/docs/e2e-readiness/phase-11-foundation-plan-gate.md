# E2E Readiness — Phase 11: Foundation plan gate

## Purpose

`Invoke-Project03E2eFoundationPlan.ps1` prepares the first real Terraform
inspection without an apply. It receives the local profile, two available AZ
names and the console-verified CloudFront prefix-list ID as transient inputs.

The script prompts locally for the RDS master password. It places that value
only in the current PowerShell process as `TF_VAR_database_master_password`,
clears it in `finally`, and never writes a `.tfvars` or `.tfplan` file. The
plan output must be reviewed in the local terminal and can be shared only
after confirming it contains no sensitive material.

## Validation

The helper has a `-DryRun` mode that performs no Terraform or AWS call. It is
used to validate input handling and its no-persistence boundary. The real
mode runs `init`, `validate`, and `plan` only; it contains no `apply` command.

## Boundary

A Terraform plan is read-only with respect to intended infrastructure, but it
does authenticate to AWS and obtains current provider information. It does not
authorize creating Foundation resources. After the plan is inspected, a new
explicit approval is required before any apply.
