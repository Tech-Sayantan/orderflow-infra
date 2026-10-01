variable "cluster_name" {
  description = "Name of the Amazon EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the Amazon EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will run."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by the EKS cluster and its worker nodes."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "Provide private subnets in at least two Availability Zones."
  }
}

variable "tags" {
  description = "Tags applied to resources created by the EKS module."
  type        = map(string)
  default     = {}
}

variable "cluster_endpoint_private_access" {
  description = "Allow workloads in the VPC to reach the Kubernetes API endpoint."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Allow kubectl access to the Kubernetes API endpoint over the internet."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "Public CIDR ranges allowed to reach the Kubernetes API endpoint."
  type        = list(string)
  default     = []

  validation {
    condition = (
      !var.cluster_endpoint_public_access ||
      (
        length(var.cluster_endpoint_public_access_cidrs) > 0 &&
        !contains(var.cluster_endpoint_public_access_cidrs, "0.0.0.0/0")
      )
    )
    error_message = "When public access is enabled, provide restricted CIDRs; 0.0.0.0/0 is not allowed."
  }
}

variable "node_instance_types" {
  description = "EC2 instance types used by the managed worker node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_group_desired_size" {
  description = "Initial desired number of worker nodes."
  type        = number
  default     = 2

  validation {
    condition = (
      var.node_group_desired_size >= var.node_group_min_size &&
      var.node_group_desired_size <= var.node_group_max_size
    )
    error_message = "desired_size must be between min_size and max_size."
  }
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 2
}

variable "cluster_admin_principal_arn" {
  description = "IAM principal granted administrator access to the EKS cluster."
  type        = string
}
