terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Run bootstrap/ first, then paste its outputs here before running terraform init.
  # bucket name pattern: {AWS_ACCOUNT_ID}-network-lab-tfstate
  backend "s3" {
    bucket         = "ACCOUNT_ID-network-lab-tfstate" # replace ACCOUNT_ID
    key            = "network-lab/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "network-lab-terraform-locks"
    encrypt        = true
  }
}
