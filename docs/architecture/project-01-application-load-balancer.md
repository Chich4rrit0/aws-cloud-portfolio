# Project 01 — Application Load Balancer delivery

## Implemented request path

```text
Internet
  -> internet-facing ALB, HTTP port 80
  -> Target Group, HTTP port 3000, health check GET /health
  -> Auto Scaling Group application instance
  -> private PostgreSQL RDS
```

The ALB runs in the two dedicated public edge subnets. Its security group accepts HTTP from the Internet and can send traffic only to port 3000 on the application security group. The EC2 instance does not accept direct Internet traffic.

## Initial delivery scope

- One HTTP listener forwards its default action to the application Target Group.
- The Target Group is attached to the existing Auto Scaling Group, so a replacement instance is registered automatically.
- Health checks require HTTP `200` from `/health` before traffic is forwarded.
- HTTPS, Route 53, ACM and CloudFront are intentionally deferred to later phases.

## Verification

The Target Group reported the application instance as healthy and the public ALB endpoint returned the Task Manager health response. This proves the full Internet-to-ALB-to-EC2 path while preserving the EC2 inbound boundary.
