
# VPC
moved {
  from = aws_vpc.main
  to   = module.networking.aws_vpc.main
}

# Subnets
moved {
  from = aws_subnet.public_a
  to   = module.networking.aws_subnet.public_a
}

moved {
  from = aws_subnet.public_b
  to   = module.networking.aws_subnet.public_b
}

moved {
  from = aws_subnet.private_a
  to   = module.networking.aws_subnet.private_a
}

moved {
  from = aws_subnet.private_b
  to   = module.networking.aws_subnet.private_b
}

# Internet Gateway
moved {
  from = aws_internet_gateway.main
  to   = module.networking.aws_internet_gateway.main
}

# Route tables
moved {
  from = aws_route_table.public
  to   = module.networking.aws_route_table.public
}

moved {
  from = aws_route_table.private
  to   = module.networking.aws_route_table.private
}

# Routes
moved {
  from = aws_route.public_internet
  to   = module.networking.aws_route.public_internet
}

moved {
  from = aws_route.private_nat
  to   = module.networking.aws_route.private_nat
}

# Route table associations
moved {
  from = aws_route_table_association.public_a
  to   = module.networking.aws_route_table_association.public_a
}

moved {
  from = aws_route_table_association.public_b
  to   = module.networking.aws_route_table_association.public_b
}

moved {
  from = aws_route_table_association.private_a
  to   = module.networking.aws_route_table_association.private_a
}

moved {
  from = aws_route_table_association.private_b
  to   = module.networking.aws_route_table_association.private_b
}

# Elastic IP
moved {
  from = aws_eip.nat
  to   = module.networking.aws_eip.nat
}

# NAT Gateway
moved {
  from = aws_nat_gateway.main
  to   = module.networking.aws_nat_gateway.main
}

moved {
  from = aws_security_group.alb
  to   = module.security.aws_security_group.alb
}

moved {
  from = aws_security_group.ec2
  to   = module.security.aws_security_group.ec2
}

moved {
  from = aws_iam_role.ec2_ssm_role
  to   = module.security.aws_iam_role.ec2_ssm_role
}

moved {
  from = aws_iam_role_policy_attachment.ssm_core
  to   = module.security.aws_iam_role_policy_attachment.ssm_core
}

moved {
  from = aws_iam_instance_profile.ec2_ssm_profile
  to   = module.security.aws_iam_instance_profile.ec2_ssm_profile
}
moved {
  from = aws_lb.main
  to   = module.load_balancer.aws_lb.main
}

moved {
  from = aws_lb_target_group.app
  to   = module.load_balancer.aws_lb_target_group.app
}

moved {
  from = aws_lb_listener.http
  to   = module.load_balancer.aws_lb_listener.http
}
moved {
  from = data.aws_ami.amazon_linux
  to   = module.compute.data.aws_ami.amazon_linux
}

moved {
  from = aws_launch_template.app
  to   = module.compute.aws_launch_template.app
}

moved {
  from = aws_autoscaling_group.app
  to   = module.compute.aws_autoscaling_group.app
}
moved {
  from = aws_cloudwatch_metric_alarm.unhealthy_targets
  to   = module.monitoring.aws_cloudwatch_metric_alarm.unhealthy_targets
}

moved {
  from = aws_cloudwatch_metric_alarm.asg_capacity
  to   = module.monitoring.aws_cloudwatch_metric_alarm.asg_capacity
}

moved {
  from = aws_sns_topic.alerts
  to   = module.monitoring.aws_sns_topic.alerts
}

moved {
  from = aws_sns_topic_subscription.email_alerts
  to   = module.monitoring.aws_sns_topic_subscription.email_alerts
}

moved {
  from = aws_cloudwatch_dashboard.main
  to   = module.monitoring.aws_cloudwatch_dashboard.main
}