# Cost Check — Phase 10: application compute

**Status:** implemented on 2026-09-07.

## Resources created

- One EC2 Launch Template with a corrected second version.
- One Auto Scaling Group: `min=1`, `desired=1`, `max=2`.
- One running `t3.micro` application instance.
- One encrypted 8 GiB gp3 root volume, configured to delete on instance termination.
- One public IPv4 address assigned by the existing public application subnet for outbound SSM, S3 and package access. The security group still has no direct inbound application rule.

## Estimated new on-demand cost

These are estimates before Free Plan credits, taxes, data transfer and usage-based services; they are not the actual bill.

- Linux `t3.micro`: USD 0.0104/hour.
- Public IPv4: USD 0.005/hour.
- 8 GiB gp3 volume: approximately USD 0.64/month while provisioned.
- EC2, IPv4 and root volume combined: approximately USD 0.39/day or USD 11.9 for a 31-day month if kept running continuously.

Existing RDS, S3 artifact storage and any future ALB/CloudWatch usage are additional costs. AWS billing data can be delayed; the existing budget alert is monitoring, not an automatic stop control.

## Cost controls and cleanup

- No NAT Gateway, ALB, CloudFront or Route 53 resource exists in this phase.
- No scaling policy is attached, so the ASG remains at desired capacity 1 unless explicitly changed.
- To stop EC2 and IPv4 charges, first scale the ASG to `min=0`, `desired=0`, `max=0`; this terminates the application instance and is a destructive action requiring approval.
- The Launch Template itself does not incur an hourly charge. Delete it only after the ASG has been removed and no replacement instance is needed.
- The RDS instance continues to incur its own running cost and has a separate cleanup decision.

## Risk of unexpected cost

- Leaving the ASG at desired capacity 1 keeps an EC2 instance, public IPv4 and root volume active.
- Manually terminating an instance while desired capacity remains 1 causes Auto Scaling to launch a replacement.
- Budget notifications are not real-time and do not stop resources automatically.
