variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "ap-south-1"
}

variable "admin_cidr" {
  type        = string
  description = "Your public IP in x.x.x.x/32 format — restricts SSH on public instances. Find it with: curl ifconfig.me"

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be a valid CIDR block (e.g. 203.0.113.5/32)."
  }
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

  validation {
    condition     = can(cidrhost(var.vpc_a.cidr, 0))
    error_message = "vpc_a.cidr must be a valid CIDR block."
  }

  validation {
    condition     = length(var.vpc_a.public_subnets) > 0 && length(var.vpc_a.private_subnets) > 0
    error_message = "vpc_a must have at least one public and one private subnet."
  }

  validation {
    condition     = alltrue([for cidr in concat(var.vpc_a.public_subnets, var.vpc_a.private_subnets) : can(cidrhost(cidr, 0))])
    error_message = "All subnet CIDRs in vpc_a must be valid CIDR blocks."
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

  validation {
    condition     = can(cidrhost(var.vpc_b.cidr, 0))
    error_message = "vpc_b.cidr must be a valid CIDR block."
  }

  validation {
    condition     = length(var.vpc_b.public_subnets) > 0 && length(var.vpc_b.private_subnets) > 0
    error_message = "vpc_b must have at least one public and one private subnet."
  }

  validation {
    condition     = alltrue([for cidr in concat(var.vpc_b.public_subnets, var.vpc_b.private_subnets) : can(cidrhost(cidr, 0))])
    error_message = "All subnet CIDRs in vpc_b must be valid CIDR blocks."
  }
}
