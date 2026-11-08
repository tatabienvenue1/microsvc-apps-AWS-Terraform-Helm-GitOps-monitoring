resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${local.cluster_slug}-AWSLoadBalancerController"
  description = "IAM policy for AWS Load Balancer Controller (IRSA). Includes permissions required by newer controller releases."
  policy      = file("${path.module}/policies/aws-load-balancer-controller-iam-policy.json")

  tags = local.common_tags
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name        = "${local.cluster_slug}-lbc-irsa"
  description = "IRSA role for AWS Load Balancer Controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:${var.aws_lbc_namespace}:${var.aws_lbc_service_account_name}"
          }
        }
      }
    ]
  })

  tags = local.common_tags

  depends_on = [module.eks]
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}
