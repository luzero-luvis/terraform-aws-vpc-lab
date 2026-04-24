locals {
  public_subnet_map = {
    for idx, cidr in var.public_subnets : cidr => {
      cidr = cidr
      az   = var.azs[idx % length(var.azs)]
    }
  }
  private_subnet_map = {
    for idx, cidr in var.private_subnets : cidr => {
      cidr = cidr
      az   = var.azs[idx % length(var.azs)]
    }
  }
}

resource "aws_subnet" "public" {
  for_each = local.public_subnet_map

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${each.key}"
    Type = "public"
    AZ   = each.value.az
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnet_map

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${each.key}"
    Type = "private"
    AZ   = each.value.az
  })
}
