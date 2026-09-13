# E2E Readiness — Phase 15: Runtime and Edge validation

## Scope and result

On 2026-09-13, the isolated Project 03 Foundation, Runtime and Edge stages
were deployed and validated in `us-east-1`. This evidence records the
execution result; it does not expose passwords, the CloudFront origin header,
Terraform state, temporary test identifiers or account-specific credentials.

## Delivered layers

- **Foundation:** isolated VPC, subnet topology, security groups, RDS,
  restricted S3 buckets, IAM instance profile and base observability.
- **Runtime:** an ALB, target group, HTTP listener, ASG with desired capacity
  one, one `t3.micro` application instance, encrypted EBS, application log
  group and a no-healthy-targets alarm with actions disabled.
- **Edge:** CloudFront default domain, OAC, a frontend bucket policy limited
  to the distribution, non-cached `/api/*` and `/health` behaviours, an ALB
  origin-header rule and a SecureString parameter for the private header.

The Runtime listener includes a narrowly scoped `/health` forwarding rule.
It associates the target group before Edge exists, allowing ALB health checks
to work. Its priority is lower than the Edge origin-header rule. The ALB
security group continues to restrict incoming traffic to the AWS-managed
CloudFront origin-facing prefix list.

## Functional evidence

The validation was performed through the deployed CloudFront HTTPS domain:

| Check | Result |
| --- | --- |
| Frontend delivery | HTTP 200 |
| `/health` | HTTP 200; Task Manager API reported healthy |
| Create temporary task | HTTP 201 |
| Update temporary task | HTTP 200 |
| List and verify task | HTTP 200 |
| Delete temporary task | HTTP 204; cleanup confirmed |
| Direct ALB request without private header | Timed out at the network boundary, as expected from the ALB security group |

CloudWatch application and bootstrap log streams were present. The target was
healthy, the ASG had one `InService` instance, and the target-health alarm was
`OK` with no automated action configured.

## Terraform convergence

After validation, both Runtime and Edge normal plans returned no pending
changes. The Edge convergence plan used the origin header only as a temporary
process environment variable obtained from Parameter Store; it was not printed
or committed.

## Deliberate limits

- No custom domain, Route 53 record, ACM certificate or WAF was deployed.
- The CloudFront-to-ALB origin protocol remains HTTP for this laboratory;
  end-to-end origin TLS needs a domain and ACM design.
- No screenshots were collected by request.
- Project 01 and Project 02 source and deployed resources were not changed.

## Next operational gate

The E2E environment remains active for any explicitly approved evidence or
failure demonstrations. Before it is left idle, run the active Cost Check and
obtain explicit approval for the destructive teardown sequence: Edge, Runtime
and then Foundation.
