# Cost Check — Phase 9: private S3 artifact delivery

**Status:** implemented on 2026-09-07. One private artifact bucket, one release ZIP and the narrowly scoped EC2 read policy now exist.

## Resources created

- One private S3 bucket in `us-east-1` for Project 01 release ZIP files.
- A narrow inline policy on the existing EC2 application role: `s3:GetObject` on `releases/*` only.
- One encrypted release ZIP, named from the Git short commit. Its local and remote sizes were verified to match after upload.

## Security verification

- All S3 Block Public Access settings are enabled.
- Object Ownership is `BucketOwnerEnforced`; ACL-based public access is disabled.
- Default object encryption and the uploaded object use SSE-S3 (`AES256`).
- The EC2 role cannot list the bucket or write or delete objects.

## Cost model

- S3 has no minimum charge; usage is billed for storage, requests and applicable transfer.
- Same-region EC2 to S3 transfer is not charged as data transfer.
- ZIP files are expected to be small. Actual cost still depends on retained size and request count.
- Versioning is intentionally disabled initially so superseded artifacts do not silently accumulate storage.
- A storage request and a small amount of S3 storage now exist. The exact charge is not yet known because billing data is delayed; the AWS Budget alert remains the cost-monitoring control, not a spending cap.

## Cleanup plan

- Before deleting the artifact bucket, delete all objects explicitly and confirm no EC2 deployment depends on it.
- Bucket deletion is destructive and requires separate approval.
- The EC2 policy should be removed after the bucket is deleted.
