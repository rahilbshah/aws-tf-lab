terraform {
  # Express what this code NEEDS, not what you happen to have installed.
  # Nothing in bootstrap/ uses a 1.16 feature, so don't gate it on 1.16.
  # (live/ will raise this if we adopt `terraform graph -format=mermaid` etc.)
  required_version = ">= 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # latest at time of writing: 6.63.0 (2026-09-03)
    }
  }

  # NO backend block here, deliberately. This config CREATES the bucket that
  # every other config stores its state in, so it cannot store its own state
  # there. bootstrap/ keeps local state forever. That is the chicken-and-egg,
  # and the answer is "one config is allowed to be special".
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project   = "saa-c03-learning"
      Component = "tf-state-bootstrap"
      ManagedBy = "terraform"
      Owner     = "Rahil"
    }
  }
}
