terraform {
  required_version = ">= 1.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  # Default AWS CLI profile ([default] in ~/.aws) is picked up automatically.
  default_tags {
    tags = {
      Project   = "saa-c03-learning"
      ManagedBy = "terraform"
      Owner     = "Rahil"
    }
  }
}
