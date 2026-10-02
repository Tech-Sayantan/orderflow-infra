locals {
  github_ecr_publisher_subject = "repo:Tech-Sayantan@298946378/orderflow-app@1386107516:ref:refs/heads/main"
}

data "aws_iam_policy_document" "github_actions_ecr_publisher_trust" {
  statement {
    sid     = "AllowOnlyOrderflowAppMainBranch"
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
      values   = [local.github_ecr_publisher_subject]
    }
  }
}

resource "aws_iam_role" "github_ecr_publisher" {
  name                 = "orderflow-github-ecr-publisher"
  assume_role_policy   = data.aws_iam_policy_document.github_actions_ecr_publisher_trust.json
  max_session_duration = 3600

  tags = {
    Project = "orderflow"
    Purpose = "ECR image publishing from GitHub Actions"
  }
}

data "aws_iam_policy_document" "github_ecr_publisher" {
  statement {
    sid       = "GetECRAuthorizationToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PublishOrderflowApplicationImages"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = local.ecr_repository_arns
  }
}

resource "aws_iam_role_policy" "github_ecr_publisher" {
  name   = "orderflow-github-ecr-publisher"
  role   = aws_iam_role.github_ecr_publisher.id
  policy = data.aws_iam_policy_document.github_ecr_publisher.json
}
