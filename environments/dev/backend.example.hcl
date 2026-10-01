# Copy this file to backend.hcl and replace the bucket with your own unique S3 bucket.
# Keep backend.hcl out of Git; it identifies your AWS account's state bucket.
bucket       = "REPLACE_WITH_YOUR_TERRAFORM_STATE_BUCKET"
key          = "orderflow/dev/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
