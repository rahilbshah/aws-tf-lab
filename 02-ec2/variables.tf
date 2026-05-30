variable "admin_ssh_cidr" {
  default = "183.82.199.244/32"
  type    = string
}

variable "ssh_public_key_path" {
  default = "~/.ssh/saa-c03-learning.pub"
  type    = string
}

variable "instance_type" {
  default = "t3.micro"
  type    = string
}