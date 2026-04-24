variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "ap-south-1"
}

variable "vpc_a" {
  description = "Configuration for VPC-A (primary, has NAT gateway)"
  type = object({
    cidr            = string
    public_subnets  = list(string)
    private_subnets = list(string)
    azs             = list(string)
  })
  default = {
    cidr            = "10.0.0.0/16"
    public_subnets  = ["10.0.1.0/24", "10.0.3.0/24"]
    private_subnets = ["10.0.2.0/24", "10.0.4.0/24"]
    azs             = ["ap-south-1a", "ap-south-1b"]
  }
}

variable "vpc_b" {
  description = "Configuration for VPC-B (peered, no NAT gateway)"
  type = object({
    cidr            = string
    public_subnets  = list(string)
    private_subnets = list(string)
    azs             = list(string)
  })
  default = {
    cidr            = "192.168.0.0/16"
    public_subnets  = ["192.168.1.0/24"]
    private_subnets = ["192.168.2.0/24"]
    azs             = ["ap-south-1a"]
  }
}
