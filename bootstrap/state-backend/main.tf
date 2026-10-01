provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "state" {
  bucket        = "orderflow-tfstate-${data.aws_caller_identity.current.account_id}-us-east-1"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project = "orderflow"
    Purpose = "terraform-state"
  }
}