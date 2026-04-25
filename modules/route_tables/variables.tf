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
  description = "ID of the Internet Gateway"
  default     = null
}

variable "create_igw_route" {
  type        = bool
  description = "Whether to add 0.0.0.0/0 → IGW route on the public route table"
  default     = false
}

variable "nat_gateway_id" {
  type        = string
  description = "ID of the NAT Gateway"
  default     = null
}

variable "create_nat_route" {
  type        = bool
  description = "Whether to add 0.0.0.0/0 → NAT route on the private route table"
  default     = false
}

variable "peer_connection_id" {
  type        = string
  description = "ID of the VPC peering connection"
  default     = null
}

variable "create_peering_route" {
  type        = bool
  description = "Whether to add peer CIDR routes on both route tables"
  default     = false
}

variable "peer_cidr" {
  type        = string
  description = "CIDR of the peer VPC — destination for peering routes"
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
