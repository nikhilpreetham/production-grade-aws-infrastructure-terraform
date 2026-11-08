# Implementation Details

This document describes how the project was built, the full resource inventory, and how the modules are wired together. The Terraform code in `environments/` and `modules/` is the source of truth.

## Build approach

1. **Flat configuration.** All resources were first written in a single `environments/dev/main.tf` with root-level addresses (for example `aws_vpc.main`) and applied to AWS in `ap-south-1`.
2. **Testing.** Failure scenarios were run against the deployed environment (see [troubleshooting.md](troubleshooting.md)).
3. **Modular refactor.** Resources were moved into five modules under `modules/`. `environments/dev/main.tf` was rewritten to call the modules.
4. **State migration.** `environments/dev/moved.tf` maps every old address to its new module address. Running `terraform plan` after the refactor produced `Plan: 0 to add, 0 to change, 0 to destroy.`, which confirmed that no infrastructure was replaced.

## Environment configuration (`environments/dev`)

| File | Purpose |
|---|---|
| `provider.tf` | Requires `hashicorp/aws` `~> 6.0`; configures the provider for `ap-south-1` |
| `variables.tf` | `project_name`, `environment`, `vpc_cidr`, `aws_region` (all with defaults) and `alert_email` (required) |
| `main.tf` | Calls the five modules and passes outputs between them |
| `moved.tf` | 32 `moved` blocks (31 resources + 1 data source) from flat to module addresses |
| `outputs.tf` | 8 root outputs: `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `target_group_arn`, `autoscaling_group_name`, `launch_template_id`, `cloudwatch_dashboard_name`, `sns_topic_arn` |
| `.terraform.lock.hcl` | Locks `hashicorp/aws` to version `6.72.0` |
| `terraform.tfvars.example` | Placeholder values; copy to `terraform.tfvars` |

## Module wiring

| Module | Inputs (source) | Outputs used by other modules |
|---|---|---|
| `networking` | `vpc_cidr`, `project_name`, `environment` (root variables) | `vpc_id`, `public_subnet_ids`, `private_subnet_ids` |
| `security` | `vpc_id` (networking), `project_name`, `environment` | `alb_security_group_id`, `ec2_security_group_id`, `ec2_ssm_instance_profile_name` |
| `load_balancer` | `vpc_id`, `public_subnet_ids` (networking), `alb_security_group_id` (security) | `target_group_arn`, `load_balancer_arn_suffix`, `target_group_arn_suffix` |
| `compute` | `private_subnet_ids` (networking), `ec2_security_group_id`, `ssm_instance_profile_name` (security), `target_group_arn` (load_balancer), `environment` | `autoscaling_group_name`, `launch_template_id` |
| `monitoring` | ARN suffixes (load_balancer), `autoscaling_group_name` (compute), `alert_email`, `aws_region`, `project_name`, `environment` | `sns_topic_arn`, `cloudwatch_dashboard_name` |

Terraform builds the dependency graph from these references, so modules are created in the correct order without explicit `depends_on` between modules.

## Resource inventory

### module.networking (16 resources)

| Address | AWS resource | Key settings |
|---|---|---|
| `aws_vpc.main` | VPC | `var.vpc_cidr` (`10.0.0.0/16`), DNS support + hostnames |
| `aws_subnet.public_a` | Subnet | `10.0.1.0/24`, `ap-south-1a`, `map_public_ip_on_launch = true` |
| `aws_subnet.public_b` | Subnet | `10.0.3.0/24`, `ap-south-1b`, `map_public_ip_on_launch = true` |
| `aws_subnet.private_a` | Subnet | `10.0.2.0/24`, `ap-south-1a` |
| `aws_subnet.private_b` | Subnet | `10.0.4.0/24`, `ap-south-1b` |
| `aws_internet_gateway.main` | Internet Gateway | |
| `aws_route_table.public` | Route table | |
| `aws_route_table.private` | Route table | |
| `aws_route.public_internet` | Route | `0.0.0.0/0` to IGW |
| `aws_route.private_nat` | Route | `0.0.0.0/0` to NAT Gateway |
| `aws_route_table_association.public_a` / `public_b` | Association | Public subnets to public route table |
| `aws_route_table_association.private_a` / `private_b` | Association | Private subnets to private route table |
| `aws_eip.nat` | Elastic IP | `domain = "vpc"` |
| `aws_nat_gateway.main` | NAT Gateway | In `public_a`; `depends_on` the IGW |

### module.security (5 resources)

| Address | AWS resource | Key settings |
|---|---|---|
| `aws_security_group.alb` | Security group | `dev-alb-sg`; in: 80, 443 from `0.0.0.0/0`; out: all |
| `aws_security_group.ec2` | Security group | `dev-ec2-sg`; in: 80 from ALB SG; out: all |
| `aws_iam_role.ec2_ssm_role` | IAM role | `dev-ec2-ssm-role`; trust: `ec2.amazonaws.com` |
| `aws_iam_role_policy_attachment.ssm_core` | Policy attachment | `AmazonSSMManagedInstanceCore` |
| `aws_iam_instance_profile.ec2_ssm_profile` | Instance profile | `dev-ec2-ssm-profile` |

### module.load_balancer (3 resources)

| Address | AWS resource | Key settings |
|---|---|---|
| `aws_lb.main` | Application Load Balancer | `dev-application-alb`, internet-facing |
| `aws_lb_target_group.app` | Target group | `dev-app-target-group`, HTTP 80; health check `/`, `200`, 30 s, thresholds 2/2 |
| `aws_lb_listener.http` | Listener | HTTP 80, forward to target group |

### module.compute (2 resources + 1 data source)

| Address | Type | Key settings |
|---|---|---|
| `data.aws_ami.amazon_linux` | Data source | Most recent Amazon Linux 2023 x86_64 HVM AMI owned by Amazon |
| `aws_launch_template.app` | Launch Template | `dev-app-server-*`, `t3.micro`, SSM profile, EC2 SG, Apache user data |
| `aws_autoscaling_group.app` | Auto Scaling Group | `dev-app-asg`, 2/2/4, private subnets, `ELB` health checks, 180 s grace, 1-minute group metrics |

### module.monitoring (5 resources)

| Address | AWS resource | Key settings |
|---|---|---|
| `aws_sns_topic.alerts` | SNS topic | `dev-infrastructure-alerts` |
| `aws_sns_topic_subscription.email_alerts` | Subscription | Protocol `email`, endpoint `var.alert_email` |
| `aws_cloudwatch_metric_alarm.unhealthy_targets` | Alarm | `UnHealthyHostCount` Maximum `> 0`, 2 × 60 s |
| `aws_cloudwatch_metric_alarm.asg_capacity` | Alarm | `GroupInServiceInstances` Minimum `< 2`, 2 × 60 s |
| `aws_cloudwatch_dashboard.main` | Dashboard | 4 widgets |

**Total: 31 managed resources and 1 data source.**

## The `moved` blocks

`moved.tf` contains 32 blocks: one for each of the 31 managed resources and one for the AMI data source (networking 16, security 5, load_balancer 3, compute 3, monitoring 5). Each block has the form:

```hcl
moved {
  from = <old root-level address>
  to   = module.<module_name>.<same resource address>
}
```

Resource names inside the modules were kept identical to the original flat names (for example `aws_vpc.main`), so only the module prefix changes. That is what made a zero-change plan possible.
