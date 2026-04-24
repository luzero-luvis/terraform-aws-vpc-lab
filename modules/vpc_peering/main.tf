# auto_accept = true works when both VPCs are in the same account and region.
# For cross-account or cross-region peering, remove auto_accept and use a
# separate aws_vpc_peering_connection_accepter resource.

resource "aws_vpc_peering_connection" "this" {
  vpc_id      = var.vpc_a_id
  peer_vpc_id = var.vpc_b_id
  auto_accept = true

  tags = merge(var.tags, { Name = var.name })
}
