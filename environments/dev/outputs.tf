output "eks_cluster_name" {
  description = "Name of the dev EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Kubernetes API endpoint for the dev cluster."
  value       = module.eks.cluster_endpoint
}

output "eks_node_group_name" {
  description = "Name of the dev managed node group."
  value       = module.eks.node_group_name
}