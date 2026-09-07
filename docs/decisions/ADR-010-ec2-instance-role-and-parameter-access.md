# ADR-010 — EC2 Instance Role and Parameter Access

- **Status:** Accepted
- **Date:** 2026-09-07

## Context

Future application instances need remote administration without SSH and need to retrieve one database password only at runtime. The role must not contain static AWS credentials or broad Parameter Store access.

## Decision

Create `portfolio-p01-ec2-role` and attach it through `portfolio-p01-ec2-profile`.

- The trust policy permits assumption only by `ec2.amazonaws.com`.
- The AWS-managed `AmazonSSMManagedInstanceCore` policy enables Systems Manager Session Manager.
- The inline `Project01ReadDatabasePassword` policy permits only `ssm:GetParameter` on `/portfolio/project-01/database/password`.
- No `ssm:GetParametersByPath`, `ssm:DescribeParameters`, write, delete, IAM administration, access key, or `AdministratorAccess` permission is granted.

The future parameter will use the default `aws/ssm` key for this cost-conscious development environment. If a customer-managed KMS key is later selected, the role policy must be reviewed to add constrained `kms:Decrypt` access before deployment.

## Consequences

- EC2 instances can be administered with Session Manager without opening SSH.
- The application can retrieve only its intended database password parameter when that parameter is created later.
- The role does not itself create secrets, databases, instances, or any persistent credential.
