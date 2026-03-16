variable "app_name" {
  description = "Nazwa kontenera"
  type        = string
}

variable "app_version" {
  description = "Docker image tag"
  type        = string
}

variable "app_port" {
  description = "Port wewnątrz kontenera"
  type        = number
}

variable "host_port" {
  description = "Port na hoście"
  type        = number
}

variable "node_env" {
  description = "NODE_ENV"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.node_env)
    error_message = "node_env musi być: development, staging lub production."
  }
}
