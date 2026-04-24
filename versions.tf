terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Run bootstrap/ first, then paste your bucket name here before terraform init.
  # bucket name pattern: {AWS_ACCOUNT_ID}-network-lab-tfstate
  backend "s3" {
    bucket       = "ACCOUNT_ID-network-lab-tfstate" # replace ACCOUNT_ID
    key          = "network-lab/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true  # S3 native locking — no DynamoDB needed (requires Terraform >= 1.10)
  }
}
