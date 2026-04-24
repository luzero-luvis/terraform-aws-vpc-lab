variable "vpc_id" {
  type        = string
  description = "ID of the VPC to attach the Internet Gateway to"
}

variable "name" {
  type        = string
  description = "Name tag for the Internet Gateway"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to merge onto every resource"
  default     = {}
}
