terraform {
  required_version = ">= 1.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # NOTE what is NOT here: a `provider "aws"` block.
  #
  # A CHILD MODULE DECLARES WHICH PROVIDERS IT NEEDS, AND NEVER CONFIGURES ONE.
  # The root module (live/dev) configures the provider once - region, profile,
  # default_tags - and Terraform passes it down. Put a provider block in here
  # and you make the module impossible to reuse in another region, and you get
  # a deprecation warning telling you so.
  #
  # Same reason there is no backend block: state belongs to the ROOT config.
  # A module has no state of its own; its resources live in the caller's state.
}
