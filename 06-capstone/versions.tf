terraform {
  required_version = ">= 1.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Provider is configured ONCE in the root module. Child modules inherit it —
# you do NOT put a provider block inside a module (they receive the root's).
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project   = "saa-c03-learning"
      ManagedBy = "terraform"
      Owner     = "Rahil"
    }
  }
}
