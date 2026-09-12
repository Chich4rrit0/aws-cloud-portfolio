# E2E Readiness — Phase 05: artifact publication design

## Source and layout

The E2E test reuses the closed Project 01 source without modifying it. The backend release ZIP contains only the `app/` directory, excluding `node_modules` and local `.env` files. Compute extracts that ZIP to `/opt/task-manager/app`.

The frontend files are published separately to the isolated private frontend bucket with `no-cache, no-store, must-revalidate`. CloudFront invalidation occurs only after Edge is deployed and only with explicit execution.

## Safety gates

`Publish-Project03E2eArtifacts.ps1` defaults to dry run. `-Execute` is required for local ZIP creation and S3 uploads; the artifact and frontend bucket names must be supplied from Foundation outputs. The script never uses Project 01 bucket names.

## Verification

Before Runtime deployment, record the ZIP SHA-256 and object key. Confirm the artifact bucket contains `releases/task-manager-<commit>.zip` and that the frontend bucket contains only intended static assets.
