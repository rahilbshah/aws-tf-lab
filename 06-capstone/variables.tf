# ROOT variables. The db_password flows: terraform.tfvars -> here -> module.database.
# It is NEVER written in a .tf file (those are committed). tfvars is gitignored.

variable "db_password" {
  description = "RDS master password — set in terraform.tfvars (gitignored) or TF_VAR_db_password"
  type        = string
  sensitive   = true
}

variable "my_ip_cidr" {
  description = "Your laptop's public IP as a /32, for the bastion SSH rule (set in terraform.tfvars)"
  type        = string
}
