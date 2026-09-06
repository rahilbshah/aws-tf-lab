provider "aws" {
  region = var.region

  # Configured ONCE, here in the root. Every module inherits it.
  default_tags {
    tags = {
      Project     = "containers-capstone"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "Rahil"
    }
  }
}
