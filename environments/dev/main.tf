module "vpc" {
  source = "../../modules/vpc"

  project_name            = "orderflow"
  environment             = "dev"
  cluster_name            = "orderflow-dev"
  vpc_cidr                = "10.40.0.0/16"
  availability_zone_count = 2
  nat_gateway_per_az      = false
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = "orderflow-dev"
  kubernetes_version = "1.36"

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  cluster_endpoint_public_access_cidrs = [var.operator_public_cidr]
  cluster_admin_principal_arn          = var.cluster_admin_principal_arn

  node_group_min_size     = 1
  node_group_desired_size = 1
  node_group_max_size     = 1

  tags = {
    Project     = "orderflow"
    Environment = "dev"
  }
}