# Project 01 — Private artifact delivery

## Purpose

The Task Manager application is packaged locally into a release ZIP and stored in a private S3 bucket. Future EC2 application instances will download that ZIP through their instance role rather than cloning the private GitHub repository or receiving developer credentials.

## Flow

```text
Developer workstation
  -> Build release ZIP from tracked application and frontend files
  -> Upload encrypted object to private S3/releases/
  -> EC2 instance role reads one release object
  -> Instance extracts and starts the API
```

## Boundaries

- The bucket blocks public access and uses `BucketOwnerEnforced` ownership.
- Objects are encrypted with SSE-S3 (`AES256`).
- The application role has only `s3:GetObject` for `releases/*`.
- `node_modules`, `.env` and `.env.local` are excluded from the ZIP.
- The artifact bucket is separate from the future frontend bucket, which will have a different CloudFront-oriented access model.

## First validated release

The first release was uploaded from the current Git commit. The local SHA-256 and local/remote object sizes were recorded during verification. No application EC2 instance, load balancer or CloudFront distribution was created in this phase.

## Operational note

S3 object storage and requests can incur charges. Retain only releases needed for rollback, and explicitly delete objects before any future bucket deletion.
