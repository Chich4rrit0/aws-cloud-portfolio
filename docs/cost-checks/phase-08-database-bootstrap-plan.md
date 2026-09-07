# Cost Check — Phase 8: database bootstrap plan

**Status:** completed and cleaned up on 2026-09-07. Billing data can be delayed, so the actual cost must be reviewed later in Billing.

## Temporary resources used

- One `t3.micro` EC2 instance.
- One attached public IPv4 address while it was running, required for outbound connectivity without a NAT Gateway.
- One encrypted 8 GiB GP3 root volume, deleted with the instance.
- One temporary IAM role and instance profile; IAM has no direct hourly charge.

## Estimated cost

- `t3.micro` Linux On-Demand in `us-east-1`: US$0.0104/hour.
- Public IPv4: US$0.005/hour when billable; entitlement applicability must be checked against the account plan.
- 8 GiB GP3: approximately US$0.64/month, prorated while the volume exists.
- Baseline while the instance runs: approximately US$0.0163/hour, excluding data transfer and package downloads.

This is separate from the already-running RDS estimate of approximately US$0.51/day.

## Cleanup result

After the app credential and permissions were validated:

1. The regular application EC2 role was updated to the app-password parameter only.
2. The bootstrap EC2 was terminated and its root volume deletion was verified.
3. The bootstrap instance profile, inline policy and IAM role were deleted.

RDS and both SecureStrings were preserved. The master-password SecureString remains temporarily until a future application connection test succeeds; it is no longer accessible to any EC2 role.
