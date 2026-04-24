variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "IDs of public subnets to associate with the public route table"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "IDs of private subnets to associate with the private route table"
}

variable "igw_id" {
  type        = string
  description = "ID of the Internet Gateway — adds 0.0.0.0/0 → IGW on the public RT"
  default     = null
}

variable "nat_gateway_id" {
  type        = string
  description = "ID of the NAT Gateway — adds 0.0.0.0/0 → NAT on the private RT"
  default     = null
}

variable "peer_connection_id" {
  type        = string
  description = "ID of the VPC peering connection — adds a peering route on both RTs"
  default     = null
}

variable "peer_cidr" {
  type        = string
  description = "CIDR of the peer VPC — used as the destination for peering routes"
  default     = null
}

variable "name_prefix" {
  type        = string
  description = "Prefix used in Name tags (e.g. 'vpc-a')"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to merge onto every resource"
  default     = {}
}
