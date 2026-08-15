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

# A SECOND provider for the replication destination region.
# `alias` is what makes multi-region possible in one config: resources that
# should live in us-west-2 declare `provider = aws.dest`. Anything that doesn't
# mention a provider keeps using the default (us-east-1) one above.
provider "aws" {
  alias  = "dest"
  region = "us-west-2"
  default_tags {
    tags = {
      Project   = "saa-c03-learning"
      ManagedBy = "terraform"
      Owner     = "Rahil"
    }
  }
}
