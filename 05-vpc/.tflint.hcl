plugin "terraform" {
  enabled = true
  preset  = "recommended"   # includes unused-declarations, naming, deprecations
}
plugin "aws" {
  enabled = true
  version = "0.48.0"        # check latest
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}