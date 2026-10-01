resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  bootstrap_self_managed_addons = false

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "vpc-cni"
  service_account_role_arn = aws_iam_role.vpc_cni.arn
  tags                     = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.vpc_cni
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "kube-proxy"
  tags         = var.tags
}

resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-general"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.node_instance_types
  capacity_type   = "ON_DEMAND"

  scaling_config {
    min_size     = var.node_group_min_size
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_ecr_pull,
    aws_eks_addon.vpc_cni
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "coredns"
  tags         = var.tags

  depends_on = [
    aws_eks_node_group.general
  ]
}