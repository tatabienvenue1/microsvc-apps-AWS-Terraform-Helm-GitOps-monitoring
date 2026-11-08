output "aws_region" {
  description = "AWS region where this stack is deployed (use with kubectl / ACM / ALB)."
  value       = var.aws_region
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_slug" {
  description = "Short slug used for EKS cluster name, node group, and IAM resource names."
  value       = local.cluster_slug
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Configure kubeconfig for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnets (use for internet-facing ALB / Ingress annotations)."
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnets (EKS workers)."
  value       = module.vpc.private_subnets
}

output "aws_load_balancer_controller_irsa_role_arn" {
  description = "Annotate Helm ServiceAccount with eks.amazonaws.com/role-arn=<this value>."
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "app_acm_certificate_arn" {
  description = "Issued ACM certificate ARN for Ingress TLS (null if ACM skipped)."
  value       = length(aws_acm_certificate_validation.app) > 0 ? aws_acm_certificate_validation.app[0].certificate_arn : null
}

output "phase1_next_steps" {
  description = "What to do after apply."
  value       = <<-EOT
    1) kubectl: ${local.kubectl_cmd}
    2) Install AWS Load Balancer Controller (Helm), setting serviceAccount.annotations.eks.amazonaws.com/role-arn to the output aws_load_balancer_controller_irsa_role_arn.
    3) Deploy Online Boutique + Ingress; set Ingress TLS to app_acm_certificate_arn (when ACM was created).
  EOT
}
