output "artifact_bucket_name" { value = aws_s3_bucket.this["artifacts"].bucket }
output "artifact_bucket_arn" { value = aws_s3_bucket.this["artifacts"].arn }
output "frontend_bucket_name" { value = aws_s3_bucket.this["frontend"].bucket }
output "frontend_bucket_arn" { value = aws_s3_bucket.this["frontend"].arn }
