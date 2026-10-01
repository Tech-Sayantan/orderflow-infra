variable "project_name" {
  description = "Project name used in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name, such as dev or prod."
  type        = string
}

variable "cluster_name" {
  description = "Future EKS cluster name used for subnet discovery tags."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 address range for the VPC."
  type        = string
  default     = "10.40.0.0/16"

  validation {
    condition = can(cidrsubnet(
      var.vpc_cidr,
      4,
      (2 * var.availability_zone_count) - 1
    ))
    error_message = "vpc_cidr must be valid and support two subnet indexes per Availability Zone with four additional prefix bits."
  }
}

variable "availability_zone_count" {
  description = "Number of Availability Zones for the public and private subnets."
  type        = number
  default     = 2

  validation {
    condition = (
      var.availability_zone_count >= 2 &&
      var.availability_zone_count <= 8 &&
      floor(var.availability_zone_count) == var.availability_zone_count
    )
    error_message = "availability_zone_count must be a whole number from 2 to 8."
  }
}

variable "nat_gateway_per_az" {
  description = "Create one NAT Gateway per AZ for production-grade egress resiliency."
  type        = bool
  default     = false
}