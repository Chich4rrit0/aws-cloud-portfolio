# Cost Check — Phase 8: database bootstrap plan

**Status:** planned only. No bootstrap IAM role, instance profile, EC2 instance, public IPv4 address or additional EBS volume exists yet.

## Proposed temporary resources

- One `t3.micro` EC2 instance.
- One attached public IPv4 address while it is running, required for outbound connectivity without a NAT Gateway.
- One encrypted 8 GiB GP3 root volume, deleted with the instance.
- One temporary IAM role and instance profile; IAM has no direct hourly charge.

## Estimated cost

- `t3.micro` Linux On-Demand in `us-east-1`: US$0.0104/hour.
- Public IPv4: US$0.005/hour when billable; entitlement applicability must be checked against the account plan.
- 8 GiB GP3: approximately US$0.64/month, prorated while the volume exists.
- Baseline while the instance runs: approximately US$0.0163/hour, excluding data transfer and package downloads.

This is separate from the already-running RDS estimate of approximately US$0.51/day.

## Cleanup plan

After the app credential and permissions are validated:

1. Update the regular application EC2 role to the app-password parameter only.
2. Terminate the bootstrap EC2 and verify its root volume was deleted.
3. Delete the bootstrap instance profile, inline policy and IAM role.

Steps 2 and 3 are destructive and require explicit user confirmation.
