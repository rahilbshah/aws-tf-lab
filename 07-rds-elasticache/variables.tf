# Inputs. Secrets are sensitive + live in terraform.tfvars (gitignored) — never in a .tf.

variable "db_password" {
  description = "RDS master password (terraform.tfvars / TF_VAR_db_password). No @, /, \", or spaces."
  type        = string
  sensitive   = true
}

variable "redis_auth_token" {
  description = "Redis AUTH token (16-128 printable chars) — required when transit encryption is on"
  type        = string
  sensitive   = true
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "Two private subnets (one per AZ) for the DB + cache subnet groups"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}
