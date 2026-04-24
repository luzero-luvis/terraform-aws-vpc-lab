output "public_rt_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_rt_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}
