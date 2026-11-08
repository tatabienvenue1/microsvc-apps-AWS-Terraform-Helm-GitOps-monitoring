# Runbook: ALB, ACM, and DNS

## Ingress has no ADDRESS

1. Check LBC pods: `kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller`
2. Verify IRSA role on ServiceAccount matches Terraform output `aws_load_balancer_controller_irsa_role_arn`.
3. Confirm VPC public subnets have tag `kubernetes.io/role/elb=1`.

## CertificateNotFound / TLS errors

- ACM ARN on Ingress must be in the **same region** as the cluster.
- Certificate must cover `ingress.host` in Helm values / Argo parameters.

## DNS / curl cannot resolve host

1. `kubectl get ingress -n online-boutique frontend` — note ALB hostname.
2. Create Route 53 **A alias** to that ALB.
3. Test: `curl -I https://boutique.<your-domain>`
4. Local cache issues: use `1.1.1.1` or `curl --resolve host:443:<alb-ip> https://host`

## 502/503 from ALB

- Backend targets unhealthy → check pod readiness and `/_healthz` on frontend.
- `kubectl describe targetgroupbinding` / controller logs for detail.
