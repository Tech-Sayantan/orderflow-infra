output "plan_role_arn" {
  description = "IAM role assumed by the main-branch Terraform plan workflow."
  value       = aws_iam_role.github_terraform_plan.arn
}

output "apply_role_arn" {
  description = "IAM role assumed by the protected infra-apply environment."
  value       = aws_iam_role.github_terraform_apply.arn
}
