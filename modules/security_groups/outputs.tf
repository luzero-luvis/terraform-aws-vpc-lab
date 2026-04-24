output "web_sg_id" {
  description = "ID of the web-facing security group"
  value       = aws_security_group.web.id
}

output "private_sg_id" {
  description = "ID of the private-tier security group"
  value       = aws_security_group.private.id
}
