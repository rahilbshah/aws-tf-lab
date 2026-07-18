# ROOT variables. The db_password flows: terraform.tfvars -> here -> module.database.
# It is NEVER written in a .tf file (those are committed). tfvars is gitignored.

variable "db_password" {
  description = "RDS master password — set in terraform.tfvars (gitignored) or TF_VAR_db_password"
  type        = string
  sensitive   = true
}
