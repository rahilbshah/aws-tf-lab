terraform {
  required_version = ">= 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    # Zips app/handler.py into a deployment package at plan time.
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project   = "saa-c03-learning"
      Lab       = "19-serverless"
      ManagedBy = "terraform"
      Owner     = "Rahil"
    }
  }
}
