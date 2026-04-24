output "public_subnet_ids" {
  description = "IDs of the public subnets (ordered by CIDR key)"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (ordered by CIDR key)"
  value       = [for s in aws_subnet.private : s.id]
}
