# Failure Simulations and Troubleshooting

This document records the failure scenarios that were tested against the deployed environment, and lists common issues with their checks.

## How the mechanisms divide the work

| Mechanism | What it watches | What it does | Configured in |
|---|---|---|---|
| ALB target health checks | HTTP `GET /` on each target every 30 s | Marks targets healthy/unhealthy; routes new requests only to healthy targets | `modules/load-balancer` (`aws_lb_target_group.app`) |
| Auto Scaling health checks | EC2 status checks and, because `health_check_type = "ELB"`, the ALB health result | Terminates unhealthy instances and launches replacements to keep desired capacity | `modules/compute` (`aws_autoscaling_group.app`) |
| CloudWatch alarms | `UnHealthyHostCount`, `GroupInServiceInstances` | Changes alarm state and runs alarm/OK actions | `modules/monitoring` |
| SNS | Messages published to `dev-infrastructure-alerts` | Delivers them to confirmed email subscribers | `modules/monitoring` |

The ALB does not replace instances, the ASG does not route traffic, and CloudWatch does not fix anything. Each mechanism reacts to the same failure on its own.

## Tested scenarios

### Scenario 1: Manual instance termination

| Step | Observation |
|---|---|
| 1 | One ASG instance was terminated from the EC2 console |
| 2 | ASG in-service capacity dropped below desired capacity (2) |
| 3 | ASG launched a replacement instance from the Launch Template |
| 4 | Capacity returned to 2 instances |
| 5 | The new instance registered with `dev-app-target-group` and passed health checks |

**What this proves:** the ASG restores capacity after an unplanned instance loss.

**What this does not prove:** a controlled rollout. That is the job of an EC2 Auto Scaling *Instance Refresh*, which replaces instances in batches while keeping a minimum healthy percentage, usually after a Launch Template or AMI change. Instance Refresh was **not** tested in this project.

### Scenario 2: Apache stopped on one instance

```bash
# Connected through Session Manager
sudo systemctl stop httpd
```

| Step | Mechanism | Observation |
|---|---|---|
| 1 | ALB health check | Requests to `/` on the instance failed |
| 2 | ALB health check | After 2 consecutive failures (unhealthy threshold), the target became `unhealthy` |
| 3 | ALB routing | New requests went only to the healthy target; the application stayed available |
| 4 | ASG (ELB health check type) | The instance was marked unhealthy, terminated and replaced |
| 5 | ALB health check | The replacement became `healthy` after 2 successful checks |

### Scenario 3: CloudWatch alarm and SNS email

| Step | Mechanism | Observation |
|---|---|---|
| 1 | CloudWatch | `UnHealthyHostCount` (Maximum) rose above 0 |
| 2 | CloudWatch | After 2 × 60-second periods, `dev-alb-unhealthy-targets` moved from `OK` to `ALARM` |
| 3 | SNS | The alarm action published to the topic; the alert email was received |
| 4 | CloudWatch | After the replacement became healthy, the alarm returned to `OK` |

The alarm also has an `ok_actions` entry, so a notification is published when it returns to `OK`.

## Common issues

| Symptom | Likely cause | Check |
|---|---|---|
| No alert emails | SNS subscription not confirmed | `aws sns list-subscriptions-by-topic ...`; a `SubscriptionArn` of `PendingConfirmation` means the email link was never clicked. Also check spam. |
| Targets stay `unhealthy` after launch | Apache not installed/started, or the user data could not reach the package repository | Session Manager: `systemctl status httpd`, `sudo cat /var/log/cloud-init-output.log`; check the private route to the NAT Gateway |
| Instances keep being replaced in a loop | App takes longer than the 180 s grace period to pass health checks, or health checks always fail | Target health `Reason` field; ASG **Activity** tab |
| Session Manager shows no instances | No outbound path to SSM endpoints, or the instance profile is missing | Instance has `dev-ec2-ssm-profile`; private route `0.0.0.0/0` points to the NAT Gateway; NAT Gateway is `available` |
| ALB returns `503` | No healthy targets registered | `aws elbv2 describe-target-health ...` |
| ALB returns `504` | Target did not respond in time | Apache status and EC2 security group rule from ALB SG |
| `dev-asg-low-capacity` in `ALARM` | Fewer than 2 instances `InService` for 2 minutes | ASG **Activity** tab, instance launch failures, service quotas |
| `terraform plan` wants to destroy and recreate resources after refactoring | Missing or wrong `moved` block | Compare `terraform state list` addresses with the `from`/`to` values in `moved.tf` |
| `terraform plan` fails with credential errors | No AWS credentials in the shell | `aws sts get-caller-identity`; set `AWS_PROFILE` |

## Useful commands

```powershell
# Target health
aws elbv2 describe-target-health --region ap-south-1 `
  --target-group-arn (aws elbv2 describe-target-groups --names dev-app-target-group --region ap-south-1 --query "TargetGroups[0].TargetGroupArn" --output text)

# Recent ASG activity
aws autoscaling describe-scaling-activities --auto-scaling-group-name dev-app-asg --max-items 5 --region ap-south-1

# Alarm states and history
aws cloudwatch describe-alarms --alarm-names dev-alb-unhealthy-targets dev-asg-low-capacity --region ap-south-1
aws cloudwatch describe-alarm-history --alarm-name dev-alb-unhealthy-targets --history-item-type StateUpdate --region ap-south-1

# Terraform state addresses
terraform state list
```
