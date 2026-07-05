# Declare inputs here as you need them. A couple are pre-seeded so you can
# start writing resources immediately; add more (min/max/desired, app_port, etc.)
# if you'd rather parameterize than hardcode.

variable "instance_type" {
  description = "EC2 instance type for the ASG launch template"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Port the app (nginx) listens on and the ALB forwards to"
  type        = number
  default     = 80
}

variable "vpc_id" {
  type    = string
  default = "vpc-06dce4220e097eacc"
}