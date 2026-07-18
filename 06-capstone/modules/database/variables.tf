# INPUTS for the database module. The root wires vpc + compute outputs into these.

variable "vpc_id" {
  description = "VPC to build the RDS + DB security group in"
  type        = string
}

variable "data_subnet_ids" {
  description = "Private data-tier subnets for the DB subnet group (2+ AZs)"
  type        = list(string)
}

variable "app_sg_id" {
  description = "App-tier security group ID — the DB allows Postgres ONLY from this SG"
  type        = string
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "appadmin"
}

variable "db_password" {
  description = "Master password for the RDS instance"
  type        = string
  sensitive   = true # keeps it out of CLI/plan output; set via terraform.tfvars (gitignored) or TF_VAR_db_password
}

variable "instance_class" {
  description = "RDS instance class (db.t3.micro is Free-Tier eligible single-AZ)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_port" {
  description = "DB port (5432 Postgres, 3306 MySQL)"
  type        = number
  default     = 5432
}
