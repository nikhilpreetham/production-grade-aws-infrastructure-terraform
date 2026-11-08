# =========================================================
# SNS TOPIC
# =========================================================

resource "aws_sns_topic" "alerts" {
  name = "dev-infrastructure-alerts"

  tags = {
    Name        = "dev-infrastructure-alerts"
    Environment = var.environment
  }
}


# =========================================================
# SNS EMAIL SUBSCRIPTION
# =========================================================

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}


# =========================================================
# CLOUDWATCH ALARM: UNHEALTHY ALB TARGETS
# =========================================================

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name        = "dev-alb-unhealthy-targets"
  alarm_description = "Triggers when ALB has unhealthy EC2 targets"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"

  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    LoadBalancer = var.load_balancer_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}


# =========================================================
# CLOUDWATCH ALARM: ASG CAPACITY
# =========================================================

resource "aws_cloudwatch_metric_alarm" "asg_capacity" {
  alarm_name        = "dev-asg-low-capacity"
  alarm_description = "Triggers when fewer than 2 EC2 instances are InService"

  namespace   = "AWS/AutoScaling"
  metric_name = "GroupInServiceInstances"

  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 2
  comparison_operator = "LessThanThreshold"

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  treat_missing_data = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}


# =========================================================
# CLOUDWATCH DASHBOARD
# =========================================================

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [

      # 1. ALB Request Count
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "ALB - Request Count"
          region = var.aws_region
          period = 60
          stat   = "Sum"
          view   = "timeSeries"

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              var.load_balancer_arn_suffix
            ]
          ]
        }
      },

      # 2. Target Health
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "Application - Target Health"
          region = var.aws_region
          period = 60
          stat   = "Average"
          view   = "timeSeries"

          metrics = [
            [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              "TargetGroup",
              var.target_group_arn_suffix
            ],
            [
              "AWS/ApplicationELB",
              "UnHealthyHostCount",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              "TargetGroup",
              var.target_group_arn_suffix
            ]
          ]
        }
      },

      # 3. Target Response Time
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Application - Target Response Time"
          region = var.aws_region
          period = 60
          stat   = "Average"
          view   = "timeSeries"

          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              "TargetGroup",
              var.target_group_arn_suffix
            ]
          ]
        }
      },

      # 4. Auto Scaling Group Capacity
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "ASG - Instance Capacity"
          region = var.aws_region
          period = 60
          stat   = "Average"
          view   = "timeSeries"

          metrics = [
            [
              "AWS/AutoScaling",
              "GroupDesiredCapacity",
              "AutoScalingGroupName",
              var.autoscaling_group_name
            ],
            [
              "AWS/AutoScaling",
              "GroupInServiceInstances",
              "AutoScalingGroupName",
              var.autoscaling_group_name
            ],
            [
              "AWS/AutoScaling",
              "GroupPendingInstances",
              "AutoScalingGroupName",
              var.autoscaling_group_name
            ]
          ]
        }
      }
    ]
  })
}