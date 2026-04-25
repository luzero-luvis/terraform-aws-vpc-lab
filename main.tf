provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project   = "network-lab"
    ManagedBy = "terraform"
    Layer     = "network"
  }
}

# ─── VPC-A ───────────────────────────────────────────────────────────────────

module "vpc_a" {
  source     = "./modules/vpc"
  cidr_block = var.vpc_a.cidr
  name       = "vpc-a"
  tags       = merge(local.common_tags, { VPC = "vpc-a" })
}

module "subnets_a" {
  source          = "./modules/subnets"
  vpc_id          = module.vpc_a.vpc_id
  public_subnets  = var.vpc_a.public_subnets
  private_subnets = var.vpc_a.private_subnets
  azs             = var.vpc_a.azs
  name_prefix     = "vpc-a"
  tags            = merge(local.common_tags, { VPC = "vpc-a" })
}

module "igw_a" {
  source = "./modules/internet_gateway"
  vpc_id = module.vpc_a.vpc_id
  name   = "vpc-a-igw"
  tags   = merge(local.common_tags, { VPC = "vpc-a" })
}

module "nat_a" {
  source           = "./modules/nat_gateway"
  public_subnet_id = module.subnets_a.public_subnet_ids[0]
  name             = "vpc-a-nat"
  tags             = merge(local.common_tags, { VPC = "vpc-a" })
}

module "vpc_peering" {
  source   = "./modules/vpc_peering"
  vpc_a_id = module.vpc_a.vpc_id
  vpc_b_id = module.vpc_b.vpc_id
  name     = "vpc-a-to-vpc-b"
  tags     = local.common_tags
}

module "route_tables_a" {
  source               = "./modules/route_tables"
  vpc_id               = module.vpc_a.vpc_id
  public_subnet_ids    = module.subnets_a.public_subnet_ids
  private_subnet_ids   = module.subnets_a.private_subnet_ids
  igw_id               = module.igw_a.igw_id
  create_igw_route     = true
  nat_gateway_id       = module.nat_a.nat_gateway_id
  create_nat_route     = true
  peer_connection_id   = module.vpc_peering.peering_connection_id
  create_peering_route = true
  peer_cidr            = var.vpc_b.cidr
  name_prefix          = "vpc-a"
  tags                 = merge(local.common_tags, { VPC = "vpc-a" })
}

module "nacl_a" {
  source             = "./modules/nacl"
  vpc_id             = module.vpc_a.vpc_id
  vpc_cidr           = var.vpc_a.cidr
  public_subnet_ids  = module.subnets_a.public_subnet_ids
  private_subnet_ids = module.subnets_a.private_subnet_ids
  admin_cidr         = var.admin_cidr
  name_prefix        = "vpc-a"
  tags               = merge(local.common_tags, { VPC = "vpc-a" })
}

module "sg_a" {
  source      = "./modules/security_groups"
  vpc_id      = module.vpc_a.vpc_id
  vpc_cidr    = var.vpc_a.cidr
  admin_cidr  = var.admin_cidr
  name_prefix = "vpc-a"
  tags        = merge(local.common_tags, { VPC = "vpc-a" })
}

# ─── VPC-B ───────────────────────────────────────────────────────────────────

module "vpc_b" {
  source     = "./modules/vpc"
  cidr_block = var.vpc_b.cidr
  name       = "vpc-b"
  tags       = merge(local.common_tags, { VPC = "vpc-b" })
}

module "subnets_b" {
  source          = "./modules/subnets"
  vpc_id          = module.vpc_b.vpc_id
  public_subnets  = var.vpc_b.public_subnets
  private_subnets = var.vpc_b.private_subnets
  azs             = var.vpc_b.azs
  name_prefix     = "vpc-b"
  tags            = merge(local.common_tags, { VPC = "vpc-b" })
}

module "igw_b" {
  source = "./modules/internet_gateway"
  vpc_id = module.vpc_b.vpc_id
  name   = "vpc-b-igw"
  tags   = merge(local.common_tags, { VPC = "vpc-b" })
}

# VPC-B has no NAT gateway — private subnets reach VPC-A via peering only
module "route_tables_b" {
  source               = "./modules/route_tables"
  vpc_id               = module.vpc_b.vpc_id
  public_subnet_ids    = module.subnets_b.public_subnet_ids
  private_subnet_ids   = module.subnets_b.private_subnet_ids
  igw_id               = module.igw_b.igw_id
  create_igw_route     = true
  create_nat_route     = false
  peer_connection_id   = module.vpc_peering.peering_connection_id
  create_peering_route = true
  peer_cidr            = var.vpc_a.cidr
  name_prefix          = "vpc-b"
  tags                 = merge(local.common_tags, { VPC = "vpc-b" })
}

module "nacl_b" {
  source             = "./modules/nacl"
  vpc_id             = module.vpc_b.vpc_id
  vpc_cidr           = var.vpc_b.cidr
  public_subnet_ids  = module.subnets_b.public_subnet_ids
  private_subnet_ids = module.subnets_b.private_subnet_ids
  admin_cidr         = var.admin_cidr
  name_prefix        = "vpc-b"
  tags               = merge(local.common_tags, { VPC = "vpc-b" })
}

module "sg_b" {
  source      = "./modules/security_groups"
  vpc_id      = module.vpc_b.vpc_id
  vpc_cidr    = var.vpc_b.cidr
  admin_cidr  = var.admin_cidr
  name_prefix = "vpc-b"
  tags        = merge(local.common_tags, { VPC = "vpc-b" })
}
