variable "operator_public_cidr" {
  description = "Public IPv4 address allowed to reach the EKS API, written as an address/32."
  type        = string

  validation {
    condition = (
      can(cidrhost(var.operator_public_cidr, 0)) &&
      endswith(var.operator_public_cidr, "/32")
    )
    error_message = "operator_public_cidr must be one IPv4 address with a /32 prefix."
  }
}

variable "cluster_admin_principal_arn" {
  description = "IAM identity that will administer the dev Kubernetes cluster."
  type        = string
}
