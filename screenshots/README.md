# Screenshots

This folder is for **genuine screenshots captured from the deployed environment**. No screenshots have been added yet.

Before adding any image, blur or crop out AWS account IDs, email addresses, public IP addresses and ARNs.

| # | Suggested file name | What it should show |
|---|---|---|
| 1 | `01-terraform-plan-no-changes.png` | `terraform plan` output: `No changes` / `0 to add, 0 to change, 0 to destroy` after the module refactor |
| 2 | `02-vpc-resource-map.png` | VPC resource map: 4 subnets, 2 route tables, IGW, NAT Gateway |
| 3 | `03-alb-application-response.png` | Browser showing `Application Server - Project 01` through the ALB DNS name |
| 4 | `04-target-group-healthy.png` | Target group with 2 healthy targets |
| 5 | `05-asg-instances.png` | Auto Scaling Group with 2 `InService` instances across 2 AZs |
| 6 | `06-asg-activity-replacement.png` | ASG activity history showing a terminated instance being replaced |
| 7 | `07-target-unhealthy.png` | Target group showing one `unhealthy` target after `systemctl stop httpd` |
| 8 | `08-session-manager.png` | Session Manager session on a private instance |
| 9 | `09-cloudwatch-alarm-in-alarm.png` | `dev-alb-unhealthy-targets` in `ALARM` state |
| 10 | `10-sns-email-notification.png` | Received SNS alarm email (sender and recipient redacted) |
| 11 | `11-cloudwatch-dashboard.png` | Dashboard with the 4 widgets |

After adding images, link them from the relevant README sections.
