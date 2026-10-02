resource "aws_s3_bucket_lifecycle_configuration" "terraform_plans" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-orderflow-dev-plan-files"
    status = "Enabled"

    filter {
      prefix = "orderflow/dev/plans/"
    }

    expiration {
      days = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}
