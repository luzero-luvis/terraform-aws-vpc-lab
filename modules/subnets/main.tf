resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index % length(var.azs)]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name  = "${var.name_prefix}-public-${count.index + 1}"
    Type  = "public"
    AZ    = var.azs[count.index % length(var.azs)]
  })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index % length(var.azs)]

  tags = merge(var.tags, {
    Name  = "${var.name_prefix}-private-${count.index + 1}"
    Type  = "private"
    AZ    = var.azs[count.index % length(var.azs)]
  })
}
