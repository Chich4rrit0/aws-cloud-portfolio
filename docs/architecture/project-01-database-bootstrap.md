# Project 01 — Database credential bootstrap

```text
Temporary EC2 (Session Manager only)
  |  read master password: exact Parameter Store path
  |  TLS PostgreSQL connection over port 5432
  v
Private RDS PostgreSQL
  |  creates taskmanager_app with database-scoped permissions
  v
Parameter Store: application password (exact new path)
  |
  v
Future application EC2 role: read application password only
```

## Guardrails

- No key pair, SSH, inbound security-group rule, Elastic IP or NAT Gateway.
- Amazon Linux 2023 AMI is resolved dynamically through the public SSM AMI parameter.
- IMDSv2 is required and the root volume is encrypted, 8 GiB GP3 and deleted on termination.
- PostgreSQL connects with `sslmode=verify-full` and the official RDS CA bundle.
- The script never echoes either password. It keeps the bootstrap instance running only for validation and then it must be terminated with explicit approval.

## Execution result

The bootstrap was executed successfully through Session Manager. It created the application login and its SecureString parameter, then the regular application EC2 role was reduced to that parameter only. The temporary EC2, root volume, instance profile and IAM role were deleted after validation.
