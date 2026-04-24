output "vpc_a_id" {
  description = "VPC-A ID"
  value       = module.vpc_a.vpc_id
}

output "vpc_b_id" {
  description = "VPC-B ID"
  value       = module.vpc_b.vpc_id
}

output "vpc_a_public_subnet_ids" {
  description = "VPC-A public subnet IDs"
  value       = module.subnets_a.public_subnet_ids
}

output "vpc_a_private_subnet_ids" {
  description = "VPC-A private subnet IDs"
  value       = module.subnets_a.private_subnet_ids
}

output "vpc_b_public_subnet_ids" {
  description = "VPC-B public subnet IDs"
  value       = module.subnets_b.public_subnet_ids
}

output "vpc_b_private_subnet_ids" {
  description = "VPC-B private subnet IDs"
  value       = module.subnets_b.private_subnet_ids
}

output "peering_connection_id" {
  description = "VPC peering connection ID (vpc-a ↔ vpc-b)"
  value       = module.vpc_peering.peering_connection_id
}

output "nat_gateway_ip" {
  description = "NAT Gateway public IP (VPC-A — used by private subnet egress)"
  value       = module.nat_a.public_ip
}

output "vpc_a_web_sg_id" {
  description = "VPC-A web-facing security group ID"
  value       = module.sg_a.web_sg_id
}

output "vpc_a_private_sg_id" {
  description = "VPC-A private-tier security group ID"
  value       = module.sg_a.private_sg_id
}

output "vpc_b_web_sg_id" {
  description = "VPC-B web-facing security group ID"
  value       = module.sg_b.web_sg_id
}

output "vpc_b_private_sg_id" {
  description = "VPC-B private-tier security group ID"
  value       = module.sg_b.private_sg_id
}
