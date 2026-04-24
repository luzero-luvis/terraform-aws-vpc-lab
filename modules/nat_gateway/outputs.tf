output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.this.id
}

output "public_ip" {
  description = "Elastic IP address allocated to the NAT Gateway"
  value       = aws_eip.nat.public_ip
}
