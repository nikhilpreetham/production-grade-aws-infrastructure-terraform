
output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.ec2.id
}

output "ec2_ssm_instance_profile_name" {
  description = "EC2 SSM instance profile name"
  value       = aws_iam_instance_profile.ec2_ssm_profile.name
}
