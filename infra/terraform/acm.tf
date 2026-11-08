resource "aws_acm_certificate" "app" {
  count = local.create_acm_certificate ? 1 : 0

  domain_name       = var.app_certificate_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.common_tags,
    { Name = "${var.project_name}-app-cert" },
  )
}

resource "aws_route53_record" "app_cert_validation" {
  count = local.create_acm_certificate ? 1 : 0

  allow_overwrite = true
  name            = one(aws_acm_certificate.app[0].domain_validation_options).resource_record_name
  records         = [one(aws_acm_certificate.app[0].domain_validation_options).resource_record_value]
  ttl             = 60
  type            = one(aws_acm_certificate.app[0].domain_validation_options).resource_record_type
  zone_id         = var.route53_hosted_zone_id
}

resource "aws_acm_certificate_validation" "app" {
  count = local.create_acm_certificate ? 1 : 0

  certificate_arn         = aws_acm_certificate.app[0].arn
  validation_record_fqdns = [aws_route53_record.app_cert_validation[0].fqdn]
}
