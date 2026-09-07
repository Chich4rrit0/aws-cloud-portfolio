# Cost Check — Phase 9: private S3 artifact delivery plan

**Status:** planned only. No artifact bucket, object, policy addition or deployment ZIP exists yet.

## Proposed resources

- One private S3 bucket in `us-east-1` for Project 01 release ZIP files.
- A narrow inline policy on the existing EC2 application role: `s3:GetObject` on `releases/*` only.

## Cost model

- S3 has no minimum charge; usage is billed for storage, requests and applicable transfer.
- Same-region EC2 to S3 transfer is not charged as data transfer.
- ZIP files are expected to be small. Actual cost still depends on retained size and request count.
- Versioning is intentionally disabled initially so superseded artifacts do not silently accumulate storage.

## Cleanup plan

- Before deleting the artifact bucket, delete all objects explicitly and confirm no EC2 deployment depends on it.
- Bucket deletion is destructive and requires separate approval.
- The EC2 policy should be removed after the bucket is deleted.
