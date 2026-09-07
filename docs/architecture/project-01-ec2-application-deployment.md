# Project 01 — EC2 application deployment

## Implemented topology

The Task Manager API runs in one Amazon Linux 2023 EC2 instance managed by an Auto Scaling Group. The group spans the two existing application subnets and starts with `min=1`, `desired=1`, and `max=2`.

```text
Private S3 release ZIP ─┐
Parameter Store secret ─┼─> EC2 instance role -> Task Manager API -> private RDS PostgreSQL
Session Manager ────────┘
```

## Security controls

- No SSH key pair or inbound public security-group rule is used.
- The application security group accepts port 3000 only from the future ALB security group.
- Session Manager is the operational access path.
- IMDSv2 is required by the Launch Template.
- The instance role reads only the deployment release prefix and the application database password parameter.
- PostgreSQL is reached through the private database security group with TLS certificate validation enabled.
- The database password is retrieved at process startup and is not stored in the artifact or a repository file.

## Bootstrap and recovery

The Launch Template downloads the private S3 release, installs the Node.js runtime dependencies, retrieves the RDS CA bundle and starts the API as a non-login system user through `systemd`.

The initial bootstrap encountered an Amazon Linux package conflict because `curl-minimal` is included in the image. A corrected Launch Template version removed the conflicting full `curl` package. The failed instance was replaced by Auto Scaling rather than being manually repaired, demonstrating an immutable recovery path.

## Validation

`scripts/aws-cli/Test-Project01ApplicationDeployment.ps1` performs an internal validation through Session Manager:

1. Reads `/health` from `localhost`.
2. Creates, reads and deletes a temporary task through `/api/tasks`.
3. Leaves no validation task in PostgreSQL.

This stage intentionally does not create an ALB, CloudFront distribution, NAT Gateway or Route 53 record.
