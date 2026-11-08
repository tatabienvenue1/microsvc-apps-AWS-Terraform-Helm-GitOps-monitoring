# Troubleshooting index

Symptom-based guide. **Setup:** [../onboarding/deployment.md](../onboarding/deployment.md)

---

## Quick index

| Symptom | Likely cause | Runbook |
|---------|--------------|---------|
| GitLab: no AWS credentials | Missing OIDC / keys | [ci-terraform.md](ci-terraform.md) |
| GitLab: `TF_STATE_BUCKET` error | CI variable unset | [ci-terraform.md](ci-terraform.md) |
| `terraform plan` skipped | Path-based rules (no TF changes) | Expected; run `make tf-plan` locally |
| Duplicate AWS resources | State mismatch | Align `backend.hcl` + CI variables |
| No ALB / Ingress ADDRESS | LBC or IRSA | [ingress-alb.md](ingress-alb.md) |
| `CertificateNotFound` | Wrong ACM ARN/region | [ingress-alb.md](ingress-alb.md) |
| Argo OutOfSync | Bad repo URL / values | [argocd-gitops.md](argocd-gitops.md) |
| Monitoring sync fails | Missing Grafana secret | [argocd-gitops.md](argocd-gitops.md) |
| `ImagePullBackOff` | Digest / NetPol / egress | Check image; tune `networkPolicy.*` |
| HTTPS DNS fails | Route 53 not aliased to ALB | [ingress-alb.md](ingress-alb.md) |
| 502/503 storefront | Pods not ready | `kubectl get pods -n online-boutique` |

---

## Kubernetes commands

```bash
kubectl get applications -n argocd
kubectl get pods -n online-boutique
kubectl get pods -n monitoring
kubectl get ingress -A
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

---

## Local validation

```bash
make validate
make helm-lint
```
