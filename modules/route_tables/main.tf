# ── Public route table ────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
    Type = "public"
  })
}

# Default route: all internet-bound traffic exits through the IGW
resource "aws_route" "public_igw" {
  count = var.create_igw_route ? 1 : 0

  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id
}

# Peering route: traffic to peer VPC CIDR goes through the peering connection
resource "aws_route" "public_peering" {
  count = var.create_peering_route ? 1 : 0

  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = var.peer_cidr
  vpc_peering_connection_id = var.peer_connection_id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_ids)

  subnet_id      = var.public_subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}

# ── Private route table ───────────────────────────────────────────────────────

resource "aws_route_table" "private" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt"
    Type = "private"
  })
}

# Default route: outbound internet traffic exits through the NAT Gateway
resource "aws_route" "private_nat" {
  count = var.create_nat_route ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id
}

# Peering route: traffic to peer VPC CIDR goes through the peering connection
resource "aws_route" "private_peering" {
  count = var.create_peering_route ? 1 : 0

  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = var.peer_cidr
  vpc_peering_connection_id = var.peer_connection_id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_ids)

  subnet_id      = var.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private.id
}
