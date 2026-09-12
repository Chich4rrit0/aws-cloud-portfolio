# E2E Readiness — Phase 06: Runtime root validation

## Purpose

The `e2e-runtime` root isolates the components that can start only after the
Foundation, database bootstrap, and artifact publication stages are complete:

- Compute: Application Load Balancer, launch template, and Auto Scaling Group.
- Operations: CloudWatch log group, dashboard, and health alarm.

It consumes IDs, names, addresses, and artifact coordinates produced by earlier
stages. It does not declare a database password or place a secret in Terraform
variables, plans, or state.

## Inputs supplied only at the future deployment checkpoint

The operator will pass Foundation outputs for the VPC, public subnet IDs,
security groups, instance profile, artifact bucket, and RDS endpoint. The
artifact object key will be emitted by the controlled publication script.

The application database password is deliberately referenced by its SSM
Parameter Store name (`/portfolio/project-03-e2e/database/password`). The
temporary bootstrap host creates that parameter before Runtime is applied.

## Static validation performed

On 2026-09-12, the portable Terraform binary ran from the `e2e-runtime`
directory with:

```powershell
terraform fmt -recursive
terraform init -backend=false -input=false -no-color
terraform validate -no-color
```

Result: `Success! The configuration is valid.` The provider lock selects the
already-reviewed AWS provider `6.64.0`.

## Deliberate boundary

No `terraform plan`, `terraform apply`, AWS API mutation, artifact upload, or
secret entry occurred in this phase. A plan and apply remain gated by a
separate explicit AWS deployment approval.
