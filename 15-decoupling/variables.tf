variable "name_prefix" {
  description = "Prefix for every resource in this lab."
  type        = string
  default     = "saa-c03-decoupling"
}

variable "visibility_timeout" {
  description = <<-EOT
    Deliberately short so the reappear-after-timeout behaviour is observable in
    seconds rather than the 30-second default. Production values are sized to
    how long processing actually takes.
  EOT
  type        = number
  default     = 10
}

variable "max_receive_count" {
  description = "Receives without deletion before a message is moved to the dead-letter queue."
  type        = number
  default     = 3
}
