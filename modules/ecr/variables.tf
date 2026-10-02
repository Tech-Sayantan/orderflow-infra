variable "repository_names" {
  description = "Private ECR repository names for OrderFlow services."
  type        = set(string)
}

variable "tags" {
  description = "Tags applied to each ECR repository."
  type        = map(string)
  default     = {}
}
