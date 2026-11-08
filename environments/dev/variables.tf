
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "production-infrastructure"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "ap-south-1"
}
variable "alert_email" {
  description = "Email address for infrastructure alerts"
  type        = string
}
