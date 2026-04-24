output "public_nacl_id" {
  description = "ID of the public NACL"
  value       = aws_network_acl.public.id
}

output "private_nacl_id" {
  description = "ID of the private NACL"
  value       = aws_network_acl.private.id
}
