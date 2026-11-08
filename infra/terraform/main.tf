data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # EKS requires subnets in at least two AZs; keep up to three for resilience/cost balance.
  selected_azs = slice(data.aws_availability_zones.available.names, 0, min(3, length(data.aws_availability_zones.available.names)))
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.selected_azs
  private_subnets = [for k, _ in local.selected_azs : cidrsubnet(var.vpc_cidr, 4, k)]
  public_subnets  = [for k, _ in local.selected_azs : cidrsubnet(var.vpc_cidr, 4, k + 4)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  tags = local.common_tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  cluster_endpoint_private_access        = var.eks_cluster_endpoint_private_access
  cluster_endpoint_public_access         = var.eks_cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs   = var.eks_cluster_endpoint_public_access_cidrs
  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = var.eks_cloudwatch_log_retention_days
  create_kms_key                         = true
  cluster_encryption_config = {
    resources = ["secrets"]
  }

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    main = {
      name           = local.node_group_name
      instance_types = var.eks_node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.eks_node_min_size
      max_size     = var.eks_node_max_size
      desired_size = var.eks_node_desired_size

      labels = {
        workload = "online-boutique"
      }

      tags = local.common_tags
    }
  }

  tags = local.common_tags
}
