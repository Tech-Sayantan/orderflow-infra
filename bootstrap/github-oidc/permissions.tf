locals {
  state_bucket_arn = "arn:aws:s3:::orderflow-tfstate-${data.aws_caller_identity.current.account_id}-us-east-1"

  terraform_state_object_arn = "${local.state_bucket_arn}/orderflow/dev/terraform.tfstate"
  terraform_lock_object_arn  = "${local.terraform_state_object_arn}.tflock"
  terraform_plan_object_arn  = "${local.state_bucket_arn}/orderflow/dev/plans/*"

  eks_cluster_arn   = "arn:aws:eks:us-east-1:${data.aws_caller_identity.current.account_id}:cluster/orderflow-dev"
  eks_nodegroup_arn = "arn:aws:eks:us-east-1:${data.aws_caller_identity.current.account_id}:nodegroup/orderflow-dev/*/*"
  eks_addon_arn     = "arn:aws:eks:us-east-1:${data.aws_caller_identity.current.account_id}:addon/orderflow-dev/*/*"

  eks_role_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/orderflow-dev-cluster-role",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/orderflow-dev-node-role",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/orderflow-dev-vpc-cni-role",
  ]

  eks_oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/*"

  terraform_read_actions = [
    "ec2:DescribeAddresses",
    "ec2:DescribeAddressesAttribute",
    "ec2:DescribeAvailabilityZones",
    "ec2:DescribeInternetGateways",
    "ec2:DescribeNatGateways",
    "ec2:DescribePrefixLists",
    "ec2:DescribeRouteTables",
    "ec2:DescribeSubnets",
    "ec2:DescribeTags",
    "ec2:DescribeVpcAttribute",
    "ec2:DescribeVpcEndpoints",
    "ec2:DescribeVpcs",
    "eks:DescribeAccessEntry",
    "eks:DescribeAddon",
    "eks:DescribeCluster",
    "eks:DescribeNodegroup",
    "eks:ListAccessEntries",
    "eks:ListAccessPolicies",
    "eks:ListAddons",
    "eks:ListAssociatedAccessPolicies",
    "eks:ListNodegroups",
    "eks:ListTagsForResource",
    "iam:GetOpenIDConnectProvider",
    "iam:GetPolicy",
    "iam:GetPolicyVersion",
    "iam:GetRole",
    "iam:ListAttachedRolePolicies",
    "iam:ListOpenIDConnectProviders",
    "iam:ListPolicyVersions",
  ]
}

data "aws_iam_policy_document" "terraform_plan" {
  statement {
    sid       = "ReadTerraformStateBucketMetadata"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [local.state_bucket_arn]
  }

  statement {
    sid       = "ListOnlyOrderflowDevStateAndPlanKeys"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "orderflow/dev/terraform.tfstate",
        "orderflow/dev/terraform.tfstate.tflock",
        "orderflow/dev/plans/*",
      ]
    }
  }

  statement {
    sid       = "ReadTerraformState"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = [local.terraform_state_object_arn]
  }

  statement {
    sid       = "ManageTerraformStateLock"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = [local.terraform_lock_object_arn]
  }

  statement {
    sid       = "StorePrivateTerraformPlan"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = [local.terraform_plan_object_arn]
  }

  statement {
    sid       = "ReadInfrastructureForPlan"
    effect    = "Allow"
    actions   = local.terraform_read_actions
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "terraform_plan" {
  name   = "orderflow-terraform-plan"
  role   = aws_iam_role.github_terraform_plan.id
  policy = data.aws_iam_policy_document.terraform_plan.json
}

data "aws_iam_policy_document" "terraform_apply" {
  statement {
    sid       = "ReadTerraformStateBucketMetadata"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [local.state_bucket_arn]
  }

  statement {
    sid       = "ListOnlyOrderflowDevStateAndPlanKeys"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "orderflow/dev/terraform.tfstate",
        "orderflow/dev/terraform.tfstate.tflock",
        "orderflow/dev/plans/*",
      ]
    }
  }

  statement {
    sid       = "ReadAndWriteTerraformState"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = [local.terraform_state_object_arn]
  }

  statement {
    sid       = "ManageTerraformStateLock"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = [local.terraform_lock_object_arn]
  }

  statement {
    sid       = "RetrieveAndDeleteReviewedPlan"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject"]
    resources = [local.terraform_plan_object_arn]
  }

  statement {
    sid       = "ReadInfrastructureForRefresh"
    effect    = "Allow"
    actions   = local.terraform_read_actions
    resources = ["*"]
  }

  statement {
    sid    = "ManageOrderflowNetwork"
    effect = "Allow"
    actions = [
      "ec2:AllocateAddress",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:CreateInternetGateway",
      "ec2:CreateNatGateway",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:CreateVpcEndpoint",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteNatGateway",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSubnet",
      "ec2:DeleteTags",
      "ec2:DeleteVpc",
      "ec2:DeleteVpcEndpoints",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateRouteTable",
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:ReleaseAddress",
      "ec2:ReplaceRoute",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ManageOrderflowEKS"
    effect = "Allow"
    actions = [
      "eks:AssociateAccessPolicy",
      "eks:CreateAccessEntry",
      "eks:CreateAddon",
      "eks:CreateCluster",
      "eks:CreateNodegroup",
      "eks:DeleteAccessEntry",
      "eks:DeleteAddon",
      "eks:DeleteCluster",
      "eks:DeleteNodegroup",
      "eks:DisassociateAccessPolicy",
      "eks:TagResource",
      "eks:UntagResource",
      "eks:UpdateAddon",
      "eks:UpdateClusterConfig",
      "eks:UpdateClusterVersion",
      "eks:UpdateNodegroupConfig",
      "eks:UpdateNodegroupVersion",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ManageOrderflowIAMRoles"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DetachRolePolicy",
      "iam:GetRole",
      "iam:ListAttachedRolePolicies",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
    ]
    resources = local.eks_role_arns
  }

  statement {
    sid       = "PassOnlyOrderflowRolesToEKS"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = local.eks_role_arns

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["eks.amazonaws.com"]
    }
  }

  statement {
    sid    = "ManageEKSOIDCProvider"
    effect = "Allow"
    actions = [
      "iam:AddClientIDToOpenIDConnectProvider",
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider",
      "iam:RemoveClientIDFromOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider",
      "iam:UntagOpenIDConnectProvider",
    ]
    resources = [local.eks_oidc_provider_arn]
  }

  statement {
    sid     = "ReadAWSManagedEKSRolePolicies"
    effect  = "Allow"
    actions = ["iam:GetPolicy", "iam:GetPolicyVersion", "iam:ListPolicyVersions"]
    resources = [
      "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
      "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    ]
  }
}

resource "aws_iam_role_policy" "terraform_apply" {
  name   = "orderflow-terraform-apply"
  role   = aws_iam_role.github_terraform_apply.id
  policy = data.aws_iam_policy_document.terraform_apply.json
}
