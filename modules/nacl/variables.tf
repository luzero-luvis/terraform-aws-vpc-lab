variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the VPC — used to scope intra-VPC NACL rules"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "IDs of public subnets to associate with the public NACL"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "IDs of private subnets to associate with the private NACL"
}

variable "admin_cidr" {
  type        = string
  description = "CIDR allowed to SSH into public instances — restrict this in production"
  default     = "0.0.0.0/0"
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
