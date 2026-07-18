# INPUTS the compute module accepts. The root wires the vpc module's outputs
# into these (module.vpc.vpc_id -> var.vpc_id, etc.).

variable "vpc_id" {
  description = "VPC to build the ALB/ASG/SGs in"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the internet-facing ALB (2+ AZs)"
  type        = list(string)
}

variable "app_subnet_ids" {
  description = "Private subnets for the ASG instances"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for the ASG"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Port the app (nginx) listens on and the ALB forwards to"
  type        = number
  default     = 80
}
