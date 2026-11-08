variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "alert_email" {
  description = "Email address for infrastructure alerts"
  type        = string
}

variable "load_balancer_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix for CloudWatch metrics"
  type        = string
}

variable "autoscaling_group_name" {
  description = "Application Auto Scaling Group name"
  type        = string
}