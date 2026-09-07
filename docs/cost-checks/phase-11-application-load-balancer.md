# Cost Check — Phase 11: Application Load Balancer

**Status:** implemented on 2026-09-07.

## Resources created

- One internet-facing Application Load Balancer across two public edge subnets.
- One HTTP listener on port 80.
- One HTTP Target Group on port 3000, attached to the application Auto Scaling Group.

## Estimated cost

These figures are estimates before Free Plan credits, taxes, data transfer and variable LCU usage; they are not the actual bill.

- ALB running charge in `us-east-1`: USD 0.0225/hour, approximately USD 0.54/day.
- LCU usage is charged separately and depends on connections, active connections, processed bytes and rule evaluations.
- Combining the running EC2, RDS and the ALB fixed hourly portion is approximately USD 1.44/day before LCU and other variable usage.

AWS billing data and Budget alerts are delayed. The budget is monitoring only and does not automatically stop the ALB.

## Cleanup plan

- Deleting the ALB stops its hourly and LCU charges. This is destructive and requires approval.
- The listener is removed with the ALB. Detach and then delete the Target Group when it is no longer used by the ASG.
- The application ASG, EC2, RDS and artifact bucket are separate resources and continue to incur their respective costs until managed or removed independently.

## Cost risk

- An ALB charges while provisioned even with little or no traffic.
- Leaving the development ALB active continuously is not compatible with a long-running low-cost lab.
- A later HTTPS/CloudFront phase may add further recurring or usage-based costs.
