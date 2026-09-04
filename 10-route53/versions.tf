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
  default_tags {
    tags = {
      Project   = "saa-c03-learning"
      ManagedBy = "terraform"
      Owner     = "Rahil"
    }
  }
}

# Secondary region, so the failover pair is a genuine cross-region story
# rather than two buckets sitting next to each other.
provider "aws" {
  alias  = "secondary"
  region = "us-west-2"
  default_tags {
    tags = {
      Project   = "saa-c03-learning"
      ManagedBy = "terraform"
      Owner     = "Rahil"
    }
  }
}
