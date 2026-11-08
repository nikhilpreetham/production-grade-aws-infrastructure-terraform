output "vpc_id" {
  description = "ID of the project VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "target_group_arn" {
  description = "ARN of the application target group"
  value       = module.load_balancer.target_group_arn
}

output "autoscaling_group_name" {
  description = "Name of the application Auto Scaling Group"
  value       = module.compute.autoscaling_group_name
}

output "launch_template_id" {
  description = "ID of the EC2 Launch Template"
  value       = module.compute.launch_template_id
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = module.monitoring.cloudwatch_dashboard_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS alert topic"
  value       = module.monitoring.sns_topic_arn
}