variable "name" {
  description = "Name prefix for everything in this lab."
  type        = string
  default     = "notes-api"
}

variable "lambda_memory_mb" {
  description = <<-EOT
    Memory in MB. Remember what this actually controls: AWS allocates CPU in
    proportion to memory, and at 1,769 MB you get one full vCPU. 128 is the
    floor and is fine for a function that just calls DynamoDB.
  EOT
  type        = number
  default     = 128

  validation {
    condition     = var.lambda_memory_mb >= 128 && var.lambda_memory_mb <= 10240
    error_message = "Lambda memory must be between 128 and 10240 MB."
  }
}

variable "lambda_timeout_seconds" {
  description = <<-EOT
    Lambda's hard ceiling is 900 (15 minutes). But this function sits behind
    API Gateway, which gives up long before that - so a long timeout here buys
    you nothing except a bill for a function nobody is waiting for any more.
    Keep it small and let failures fail fast.
  EOT
  type        = number
  default     = 10

  validation {
    condition     = var.lambda_timeout_seconds > 0 && var.lambda_timeout_seconds <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention. Short - this is a lab."
  type        = number
  default     = 1
}
