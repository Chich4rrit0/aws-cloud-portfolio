# Project 01 — Deployment Readiness Preflight

This preflight validates the local AWS CLI context before any command that creates infrastructure for Project 01.

## Command

Run from the repository root:

```powershell
.\scripts\powershell\Test-AwsPortfolioPreflight.ps1 -ProfileName '<your-aws-cli-profile>'
```

The profile name is deliberately a parameter. It is not stored in the repository, and the command never prints credentials or an AWS account ID.

## What it checks

- AWS CLI is available in `PATH`.
- The selected CLI profile resolves to the agreed Project 01 region: `us-east-1`.
- Authentication works through AWS STS.
- The account Free Plan state and available credits can be queried.
- Whether the session is root is displayed as a warning, without exposing the ARN.

## What it does not do

- It does not create, modify, stop, or delete AWS resources.
- It does not create access keys, write credentials, or contact GitHub.
- It does not replace AWS Budgets alerts or impose a hard spend cap.

## Gate before infrastructure

Before creating VPC, ALB, EC2, RDS, S3, CloudFront, or any billable resource:

1. Run this preflight successfully.
2. Review the current Free Plan / credit result.
3. Review the resource-specific cost and cleanup plan.
4. Obtain explicit approval for the creation action.
