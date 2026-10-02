locals {
  github_apply_subject = "repo:Tech-Sayantan@298946378/orderflow-infra@1400498140:environment:infra-apply"
  github_plan_subject  = "repo:Tech-Sayantan@298946378/orderflow-infra@1400498140:ref:refs/heads/main"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    sid     = "AllowOnlyProtectedGitHubApplyEnvironment"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_apply_subject]
    }
  }
}

data "aws_iam_policy_document" "github_actions_plan_trust" {
  statement {
    sid     = "AllowOnlyOrderflowInfraMainBranch"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_plan_subject]
    }
  }
}

resource "aws_iam_role" "github_terraform_apply" {
  name                 = "orderflow-github-terraform-apply"
  assume_role_policy   = data.aws_iam_policy_document.github_actions_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "github_terraform_plan" {
  name                 = "orderflow-github-terraform-plan"
  assume_role_policy   = data.aws_iam_policy_document.github_actions_plan_trust.json
  max_session_duration = 3600
}
