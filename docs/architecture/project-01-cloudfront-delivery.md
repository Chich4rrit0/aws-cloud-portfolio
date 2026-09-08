# Project 01 — CloudFront delivery and protected ALB origin

## Implemented request path

```text
Viewer (HTTPS)
  -> CloudFront
      -> private S3 frontend origin through Origin Access Control
      -> /api/* and /health to ALB over HTTP
          -> header-guarded listener rule
              -> healthy EC2 target in the Auto Scaling Group
```

CloudFront redirects viewer HTTP requests to HTTPS and uses its default distribution domain. A custom domain, ACM certificate and Route 53 record are deferred to a later phase.

## Static frontend origin

The frontend bucket blocks all public access, uses Bucket Owner Enforced ownership and SSE-S3 encryption. The only read policy permits the CloudFront service principal for this specific distribution through Origin Access Control (OAC).

The frontend uses relative `/api/*` paths. CloudFront therefore routes static files and API traffic through one browser origin without CORS configuration.

## ALB origin guard

The AWS-managed CloudFront origin-facing prefix list was not available in this account at implementation time. Instead, CloudFront adds an origin-only custom header to ALB requests. The header value is generated at runtime, stored as a SecureString in Parameter Store and never committed to the repository.

The ALB listener forwards only requests with that header to the Target Group. Its default action is a fixed HTTP `403`, so direct ALB requests are rejected. This is an application-layer origin guard; the ALB security group still permits TCP connection attempts on port 80.

CloudFront-to-ALB origin traffic uses HTTP temporarily because the ALB does not yet have an ACM certificate or custom domain. Viewer-to-CloudFront traffic is HTTPS. End-to-end HTTPS is a future improvement.

## Validation and deployment

`Publish-Project01Frontend.ps1` syncs frontend files with no-cache headers and creates a CloudFront invalidation. `Test-Project01CloudFrontDelivery.ps1` validates HTTPS frontend delivery, health and PostgreSQL-backed CRUD, deleting its temporary task afterwards.
