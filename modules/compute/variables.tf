variable "environment" {
  description = "Environment name"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EC2 instances"
  type        = list(string)
}

variable "ec2_security_group_id" {
  description = "EC2 security group ID"
  type        = string
}

variable "ssm_instance_profile_name" {
  description = "IAM instance profile for SSM access"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN"
  type        = string
}