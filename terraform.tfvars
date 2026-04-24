aws_region = "ap-south-1"

# Your public IP — run: curl ifconfig.me
# Use x.x.x.x/32 to lock SSH to just your machine
admin_cidr = "115.246.211.179/32"

vpc_a = {
  cidr            = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.2.0/24", "10.0.4.0/24"]
  azs             = ["ap-south-1a", "ap-south-1b"]
}

vpc_b = {
  cidr            = "192.168.0.0/16"
  public_subnets  = ["192.168.1.0/24"]
  private_subnets = ["192.168.2.0/24"]
  azs             = ["ap-south-1a"]
}
