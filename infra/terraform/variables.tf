variable "aws_region" {
  description = "AWS region for EKS and networking."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Human-readable project name (tags, VPC name). May be long."
  type        = string
  default     = "online-boutique"
}

variable "cluster_id" {
  description = "Short identifier for EKS cluster, node group, and IAM resources (<=17 chars recommended; letters/digits/hyphen). If null, project_name is used, truncated to 17 characters when longer, so AWS IAM name_prefix limits are satisfied."
  type        = string
  default     = null
  nullable    = true
}

variable "vpc_cidr" {
  description = "VPC CIDR."
  type        = string
  default     = "10.0.0.0/16"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.31"
}

variable "eks_cluster_endpoint_private_access" {
  description = "Enable private access to the EKS API endpoint."
  type        = bool
  default     = true
}

variable "eks_cluster_endpoint_public_access" {
  description = "Enable public access to the EKS API endpoint."
  type        = bool
  default     = true
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks that can access the EKS public API endpoint. Restrict this list for production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_cloudwatch_log_retention_days" {
  description = "Retention period for EKS control plane CloudWatch logs."
  type        = number
  default     = 365
}

variable "eks_node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "eks_node_desired_size" {
  description = "Desired worker count (dev-sized default)."
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  type    = number
  default = 1
}

variable "eks_node_max_size" {
  type    = number
  default = 4
}

variable "tags" {
  description = "Common tags applied to supported resources."
  type        = map(string)
  default     = {}
}

# --- Phase 1: TLS (ACM) + Route 53 DNS validation (optional) ---

variable "app_certificate_domain_name" {
  description = "FQDN for the public HTTPS endpoint (e.g. boutique.example.com). Must exist in the Route 53 zone below. Leave null to skip ACM until you have a domain."
  type        = string
  default     = null
  nullable    = true
}

variable "route53_hosted_zone_id" {
  description = "Route 53 public hosted zone ID (e.g. Z123...) where DNS validation records will be created. Leave null to skip ACM."
  type        = string
  default     = null
  nullable    = true
}

# --- IRSA: AWS Load Balancer Controller service account ---

variable "aws_lbc_namespace" {
  description = "Kubernetes namespace where the AWS Load Balancer Controller ServiceAccount will live (Helm default is often kube-system)."
  type        = string
  default     = "kube-system"
}

variable "aws_lbc_service_account_name" {
  description = "ServiceAccount name annotated for IRSA (must match Helm values when you install the controller)."
  type        = string
  default     = "aws-load-balancer-controller"
}
