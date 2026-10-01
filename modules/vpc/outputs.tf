output "vpc_id" {
  description = "ID of the VPC created by this module."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "IPv4 CIDR range assigned to the VPC."
  value       = aws_vpc.this.cidr_block
}

output "availability_zones" {
  description = "Availability Zones selected for this VPC."
  value       = local.azs
}

output "public_subnet_ids" {
  description = "Public subnet IDs, in the same order as availability_zones."
  value       = [for az in local.azs : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs, in the same order as availability_zones."
  value       = [for az in local.azs : aws_subnet.private[az].id]
}

output "public_subnet_ids_by_az" {
  description = "Public subnet IDs keyed by Availability Zone."
  value       = { for az in local.azs : az => aws_subnet.public[az].id }
}

output "private_subnet_ids_by_az" {
  description = "Private subnet IDs keyed by Availability Zone."
  value       = { for az in local.azs : az => aws_subnet.private[az].id }
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs, keyed by AZ or by shared when using one NAT Gateway."
  value       = { for key, nat in aws_nat_gateway.this : key => nat.id }
}

output "s3_gateway_endpoint_id" {
  description = "ID of the S3 gateway endpoint associated with this VPC's route tables."
  value       = aws_vpc_endpoint.s3.id
}