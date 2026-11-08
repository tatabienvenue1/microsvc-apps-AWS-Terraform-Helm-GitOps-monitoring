locals {
  # EKS module builds IAM role name_prefix from cluster / node group names; AWS limits prefix to 38 chars.
  # Keep a short slug for Kubernetes/IAM names; keep project_name for human-readable tags and VPC name.
  raw_cluster_slug = lower(trimspace(replace(coalesce(var.cluster_id, var.project_name), "_", "-")))
  # Node-group IAM name_prefix includes "<name>-eks-node-group-"; keep slug <=17 when truncated.
  cluster_slug    = length(local.raw_cluster_slug) > 17 ? substr(local.raw_cluster_slug, 0, 17) : local.raw_cluster_slug
  cluster_name    = "${local.cluster_slug}-eks"
  node_group_name = "${local.cluster_slug}-ng"

  common_tags = merge(
    {
      Project = var.project_name
    },
    var.tags,
  )

  create_acm_certificate = (
    var.app_certificate_domain_name != null && var.app_certificate_domain_name != "" &&
    var.route53_hosted_zone_id != null && var.route53_hosted_zone_id != ""
  )

  kubectl_cmd = "aws eks update-kubeconfig --region ${var.aws_region} --name ${local.cluster_name}"
}

