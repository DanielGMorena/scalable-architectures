variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "project_name" {
  description = "Name of the project (lowercase, no spaces)"
  type        = string
  default     = "cloudfs"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "northeurope"
}

variable "apim_publisher_name" {
  description = "API Management publisher name"
  type        = string
  default     = "Cloud File Storage"
}

variable "apim_publisher_email" {
  description = "API Management publisher email (REQUIRED)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "CloudFileStorage"
    ManagedBy   = "Terraform"
  }
}
