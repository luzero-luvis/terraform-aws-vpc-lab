variable "public_subnet_id" {
  type        = string
  description = "ID of the public subnet to place the NAT Gateway in"
}

variable "name" {
  type        = string
  description = "Name tag for the NAT Gateway and its Elastic IP"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to merge onto every resource"
  default     = {}
}
