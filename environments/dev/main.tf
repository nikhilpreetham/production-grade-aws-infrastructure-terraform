# =========================================================
# MODULE 1: NETWORKING
# =========================================================

module "networking" {
  source = "../../modules/networking"

  vpc_cidr     = var.vpc_cidr
  project_name = var.project_name
  environment  = var.environment
}


# =========================================================
# MODULE 2: SECURITY
# =========================================================

module "security" {
  source = "../../modules/security"

  vpc_id       = module.networking.vpc_id
  project_name = var.project_name
  environment  = var.environment
}


# =========================================================
# MODULE 3: LOAD BALANCER
# =========================================================

module "load_balancer" {
  source = "../../modules/load-balancer"

  vpc_id                = module.networking.vpc_id
  alb_security_group_id = module.security.alb_security_group_id
  public_subnet_ids     = module.networking.public_subnet_ids
}


# =========================================================
# MODULE 4: COMPUTE
# =========================================================

module "compute" {
  source = "../../modules/compute"

  environment               = var.environment
  private_subnet_ids        = module.networking.private_subnet_ids
  ec2_security_group_id     = module.security.ec2_security_group_id
  ssm_instance_profile_name = module.security.ec2_ssm_instance_profile_name
  target_group_arn          = module.load_balancer.target_group_arn
}


# =========================================================
# MODULE 5: MONITORING
# =========================================================

module "monitoring" {
  source = "../../modules/monitoring"

  environment  = var.environment
  aws_region   = var.aws_region
  project_name = var.project_name
  alert_email  = var.alert_email

  load_balancer_arn_suffix = module.load_balancer.load_balancer_arn_suffix
  target_group_arn_suffix  = module.load_balancer.target_group_arn_suffix
  autoscaling_group_name   = module.compute.autoscaling_group_name
}