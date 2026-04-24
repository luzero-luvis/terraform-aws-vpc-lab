variable "vpc_a_id" {
  type        = string
  description = "ID of the requester VPC (VPC-A)"
}

variable "vpc_b_id" {
  type        = string
  description = "ID of the accepter VPC (VPC-B)"
}

variable "name" {
  type        = string
  description = "Name tag for the peering connection"
  default     = "vpc-a-to-vpc-b"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to merge onto every resource"
  default     = {}
}
