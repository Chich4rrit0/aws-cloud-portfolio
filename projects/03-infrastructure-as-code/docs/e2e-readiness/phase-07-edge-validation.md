# E2E Readiness — Phase 07: Edge root design and validation

## Purpose

The `e2e-edge` root is the final deployable stage. It accepts only non-secret
outputs from Foundation and Runtime plus the origin header supplied locally at
execution time. It creates the CloudFront distribution, Origin Access Control,
private-bucket policy, API and health behaviours, and the ALB listener rule
that admits requests only when the private origin header is present.

## Secret handling

`origin_header_value` is sensitive and has no default. At the future
deployment checkpoint it must be passed through a short-lived local
environment variable rather than committed to a `.tfvars` file or entered on
the command line. Terraform necessarily records the resource configuration in
its local E2E state; that state is ignored by Git and is deleted only after a
verified teardown.

For operational discovery, the same value is stored as a `SecureString` in
`/portfolio/project-03-e2e/cloudfront/origin-header`. It is not exposed as a
Terraform output.

## Static validation performed

On 2026-09-12, the portable Terraform binary ran `fmt`, `init -backend=false`,
and `validate` against all four roots: the original `lab` root and
`e2e-foundation`, `e2e-runtime`, and `e2e-edge`. Every root returned
`Success! The configuration is valid.` with AWS provider `6.64.0`.

## Expected verification after an approved apply

1. The CloudFront default domain returns the frontend through HTTPS.
2. `/health` is forwarded to the ALB and returns a healthy response.
3. `/api/*` reaches the API without caching mutations.
4. Direct ALB requests do not match the guarded listener rule.
5. The frontend S3 bucket allows reads only from this CloudFront distribution.

## Deliberate boundary

This phase defines and statically validates Terraform only. No origin secret
has been generated, no SSM parameter has been created, and no CloudFront,
ALB, S3, or other AWS resource has been deployed.
