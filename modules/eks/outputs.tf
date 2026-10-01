output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint for the cluster."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Public CA certificate data used to verify the cluster API."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "node_group_name" {
  description = "Name of the managed worker node group."
  value       = aws_eks_node_group.general.node_group_name
}