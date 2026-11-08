# Cost and Security Review

## Cost

This environment uses several services that are billed by the hour while deployed, whether or not it receives traffic. Prices change and differ by region, so check the [AWS Pricing Calculator](https://calculator.aws/) for `ap-south-1` rather than relying on fixed figures.

| Resource | Quantity | Billing basis | Notes |
|---|---|---|---|
| NAT Gateway | 1 | Per hour + per GB processed | Usually the largest cost in a small lab |
| Application Load Balancer | 1 | Per hour + Load Balancer Capacity Units | Billed even with no traffic |
| Public IPv4 addresses | NAT Elastic IP + ALB public IPs | Per IP per hour | AWS charges for all public IPv4 addresses |
| EC2 `t3.micro` | 2 (up to 4) | Per instance hour | May be partly covered by free tier if the account is eligible |
| EBS volumes | 1 per instance | Per GB-month | Root volumes from the AMI |
| CloudWatch alarms | 2 | Per alarm per month | Within or near the free-tier allowance |
| CloudWatch dashboard | 1 | Per dashboard per month | Free-tier allowance covers a small number of dashboards |
| SNS email | Low volume | Per notification | Negligible at lab volumes |
| Cross-AZ data transfer | Private subnet B to NAT in AZ A | Per GB | Small for this workload |

**Cost controls used or recommended:**

- Run `terraform destroy` when the environment is not in use (see the README cleanup section).
- A single NAT Gateway was chosen to keep cost down, at the price of availability (see Known Limitations in the README).
- Set an AWS Budget alert on the account.

## Security

### Controls in place

| Control | Implementation |
|---|---|
| Network isolation | EC2 instances run in private subnets with no public IPs |
| Least-exposure ingress | EC2 security group allows TCP 80 only from the ALB security group |
| No SSH | No port 22 rule; no key pair in the Launch Template |
| Session Manager | IAM role with only `AmazonSSMManagedInstanceCore`; sessions are IAM-authenticated |
| Secrets out of code | No credentials in Terraform files; the alert email is supplied through an ignored `terraform.tfvars` |
| Provider pinning | `.terraform.lock.hcl` committed to keep provider versions consistent |

### Repository review (before publishing)

| Check | Result |
|---|---|
| `terraform.tfstate`, `terraform.tfstate.backup` | Not tracked; excluded by `*.tfstate` / `*.tfstate.*` |
| `terraform.tfvars` | Not tracked; excluded by `*.tfvars` |
| `terraform-state-before-modules.json` | Not tracked; excluded by name |
| `main.tf.stage6-backup` | Not tracked; excluded by `*.stage6-backup` |
| `.terraform/` provider binaries | Not tracked; excluded by `**/.terraform/*` |
| AWS access keys / secret keys / session tokens | None found in tracked files |
| AWS account IDs | None found in tracked files |
| Personal email address | Not present in tracked files; the example file uses `your-email@example.com` |
| Key and environment files | `*.pem`, `*.key`, `.env`, `.env.*` added to `.gitignore` |

> Terraform state stores resource IDs, ARNs (which include the AWS account ID) and the SNS email endpoint in plain text. Treat local state files as sensitive. For shared use, move state to an encrypted S3 backend with restricted access.

### Gaps and recommended hardening

| Gap | Recommendation |
|---|---|
| HTTP only; port 443 is open on the ALB SG with no HTTPS listener | Add an ACM certificate and HTTPS listener, redirect 80 to 443, or remove the unused 443 rule |
| Unrestricted egress (`0.0.0.0/0`, all protocols) on both security groups | Limit EC2 egress to HTTPS (443) and required ports; limit ALB egress to the EC2 security group on port 80 |
| Instance metadata settings use defaults | Set `metadata_options { http_tokens = "required" }` in the Launch Template to enforce IMDSv2 |
| EBS encryption not explicitly set | Enable EBS encryption by default in the account or set `encrypted = true` in the Launch Template |
| Local state without locking | Use an S3 backend with encryption and state locking |
| No ALB access logs | Enable ALB access logs to an S3 bucket |
| No VPC Flow Logs | Enable Flow Logs to CloudWatch Logs or S3 |
| SNS topic not encrypted with KMS | Add `kms_master_key_id` if notifications may contain sensitive data |
| No static analysis | Run `tflint` and `checkov` (or `tfsec`) in CI |
