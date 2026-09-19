variable "name" {
  description = "Prefix for everything."
  type        = string
  default     = "capstone"
}

# ---- network ------------------------------------------------------------
variable "vpc_cidr" {
  description = "VPC CIDR. /16 leaves room for six /24 subnets with space to spare."
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Two public subnets, one per AZ. ALB and the NAT gateway live here."
  type        = list(string)
  default     = ["10.30.0.0/24", "10.30.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Two private subnets, one per AZ. ECS tasks live here; egress via NAT."
  type        = list(string)
  default     = ["10.30.10.0/24", "10.30.11.0/24"]
}

variable "isolated_subnet_cidrs" {
  description = "Two isolated subnets, one per AZ. RDS and ElastiCache. NO route to the internet at all."
  type        = list(string)
  default     = ["10.30.20.0/24", "10.30.21.0/24"]
}

# ---- app / ECS ----------------------------------------------------------
variable "container_port" {
  description = "The Flask app listens here."
  type        = number
  default     = 8080
}

variable "image_tag" {
  description = "Which tag of the ECR image to run. Change it and re-apply to deploy."
  type        = string
  default     = "v1"
}

variable "desired_count" {
  description = "Tasks to keep running. 2 so you can see the ALB distribute."
  type        = number
  default     = 2
}

variable "task_cpu" {
  description = "Fargate CPU units. 256 = 0.25 vCPU."
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Fargate memory MiB. With cpu 256, valid values are 512 / 1024 / 2048."
  type        = string
  default     = "512"
}

# ---- data ---------------------------------------------------------------
variable "db_name" {
  type    = string
  default = "capstone"
}

variable "db_username" {
  description = "Master username. The PASSWORD is not a variable anywhere - RDS generates it into Secrets Manager (phase 4)."
  type        = string
  default     = "capstone_admin"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "cache_node_type" {
  type    = string
  default = "cache.t3.micro"
}

# ---- autoscaling --------------------------------------------------------
variable "autoscale_min" {
  type    = number
  default = 1
}

variable "autoscale_max" {
  type    = number
  default = 4
}

variable "autoscale_cpu_target" {
  description = "Target-tracking: keep average CPU near this percent by adding/removing tasks."
  type        = number
  default     = 50
}

variable "log_retention_days" {
  type    = number
  default = 1
}
