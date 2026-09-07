# Cost Check — Phase 6: Instance Access IAM

**Scope:** EC2 IAM role, instance profile, managed policy attachment, and one inline policy.

## Resources created

- `portfolio-p01-ec2-role`
- `portfolio-p01-ec2-profile`
- IAM policy attachments only.

## Resources that generate cost

- No direct hourly charge is expected from the IAM role, instance profile, or policy attachments.
- No EC2 instance, Session Manager session, Parameter Store parameter, KMS key, or secret was created in this phase.

## Resources that can be stopped or deleted

- IAM configuration objects cannot be stopped.
- Detach the instance profile from EC2 first when such instances exist; then remove policies, instance profile, and role only with explicit destructive approval.

## Unexpected-cost risk

- None from the IAM objects themselves in this phase.
- A future SecureString parameter may have applicable KMS usage considerations. Reassess cost and security when creating the database credential.
