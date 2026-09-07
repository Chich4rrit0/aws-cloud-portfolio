# Project 01 — Instance Access Implementation

## Implemented IAM objects

| Object | Purpose |
| --- | --- |
| `portfolio-p01-ec2-role` | Runtime identity for future EC2 application instances |
| `portfolio-p01-ec2-profile` | Instance profile that attaches the role to EC2 |
| `AmazonSSMManagedInstanceCore` | Session Manager connectivity and managed-node capability |
| `Project01ReadDatabasePassword` | Read one future Parameter Store value only |

## Security properties

- No access keys are issued to the role.
- The role trust policy accepts only the EC2 service principal.
- SSH remains excluded from the network design.
- The role cannot list, write, or delete Parameter Store values.
- The database password parameter has not been created yet; no secret exists in the repository or this documentation.

## Runtime flow

```text
EC2 instance
  → Instance Profile
  → EC2 Role
  → Systems Manager Session Manager

Application process
  → ssm:GetParameter on one approved path
  → Parameter Store SecureString (future phase)
```
