variable "vpc_id" {
  type        = string
  description = "ID of the VPC to create subnets in"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of CIDR blocks for public subnets"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of CIDR blocks for private subnets"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones — subnets cycle through this list"
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
