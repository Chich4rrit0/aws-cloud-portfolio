# Cost Check — Phase 3: Deployment Readiness

**Scope:** AWS CLI preflight script and deployment-readiness documentation.

## Resources created

- Local PowerShell script and documentation only.
- No AWS infrastructure.

## Resources that generate cost

- None.

## Resources that can be stopped or deleted

- None. The preflight makes read-only AWS API calls and leaves no running resource.

## Unexpected-cost risk

- The preflight itself does not incur infrastructure charges.
- It must be run before every infrastructure-creation phase because Budget notifications are alerts, not an instant hard stop.
- A successful Free Plan / credits result is not permission to create resources without a separate cost review and explicit approval.
