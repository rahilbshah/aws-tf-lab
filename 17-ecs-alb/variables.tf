# Seeded so you can start writing resources immediately.

variable "name" {
  description = "Name prefix for everything in this lab"
  type        = string
  default     = "ecs-hello"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs for the two public subnets (ALB lives here)"
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for the two private subnets (Fargate tasks live here)"
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "container_image" {
  description = "Public image to run. Renders server name/address/hostname, so you can see the LB distributing."
  type        = string
  default     = "nginxdemos/hello"
}

variable "container_port" {
  description = "Port the container listens on. nginxdemos/hello serves HTTP on 80."
  type        = number
  default     = 80
}

variable "desired_count" {
  description = "How many tasks the service keeps running. Needs to be >= 2 to see load balancing."
  type        = number
  default     = 2
}

variable "task_cpu" {
  description = "Fargate CPU units. 256 = 0.25 vCPU. Valid CPU/memory pairs are fixed - see the build notes in ecs.tf."
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Fargate memory in MiB. With cpu=256 the only valid values are 512, 1024, 2048."
  type        = string
  default     = "512"
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention. Keep it short - this is a lab."
  type        = number
  default     = 1
}
