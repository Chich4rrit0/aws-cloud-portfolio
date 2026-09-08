# Cost Check — Phase 12: CloudFront frontend delivery

**Status:** implemented on 2026-09-08.

## Resources created

- One private S3 frontend bucket with a small set of static files.
- One CloudFront Origin Access Control and a bucket policy scoped to one distribution.
- One CloudFront distribution using the default domain, Price Class 100 and HTTPS viewer delivery.
- One standard Parameter Store SecureString used only as the CloudFront-to-ALB origin guard.
- One CloudFront invalidation to publish the corrected frontend copy.

## Cost model

- S3 has no minimum charge; storage and requests are usage-based.
- CloudFront delivery, requests and invalidations can generate usage charges. No paid CloudFront flat-rate plan was selected.
- The current frontend footprint and validation traffic are very small, but this is an estimate, not the actual bill.
- Existing EC2, RDS and ALB costs remain the primary recurring development costs. CloudFront adds no intentional fixed hourly resource charge in this design, but usage is variable.

AWS billing data and the budget alert can be delayed and do not stop resources automatically.

## Cost controls and cleanup

- Frontend assets use no-cache headers so a small deployment does not require long-lived stale cache entries.
- Do not create invalidations unnecessarily; each is a usage event.
- To remove this delivery path, first remove the ALB header guard or decommission the ALB, then disable and delete the CloudFront distribution, remove the OAC policy/control, delete all frontend objects and finally delete the bucket.
- Bucket, distribution and parameter deletion are destructive actions and require explicit approval.

## Risk of unexpected cost

- Public CloudFront URLs can receive traffic. The current default-domain distribution has no WAF rule or custom domain yet.
- The ALB remains the largest added cost in this delivery path because it charges while provisioned even when CloudFront cache traffic is low.
