terraform {
  required_version = ">= 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # The state bucket from bootstrap/. Six lines, already built, and it means a
  # laptop failure mid-project loses nothing. use_lockfile = native S3 locking;
  # no DynamoDB table (deprecated).
  backend "s3" {
    bucket       = "tfstate-626210706989"
    key          = "18-containers-capstone/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project   = "saa-c03-learning"
      Lab       = "18-containers-capstone"
      ManagedBy = "terraform"
      Owner     = "Rahil"
    }
  }
}
