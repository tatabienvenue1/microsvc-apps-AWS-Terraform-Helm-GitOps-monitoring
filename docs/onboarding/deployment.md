# Deployment guide

Phased operator guide for **Online Boutique on AWS**.  
**Detailed commands:** [runbook.md](runbook.md) · **Architecture:** [../architecture/overview.md](../architecture/overview.md) · **Security:** [../../SECURITY.md](../../SECURITY.md)

---

## Fork setup (replace placeholders)

| Location | Replace |
|----------|---------|
| `deploy/argocd/overlays/<env>/online-boutique-patch.yaml` | `repoURL`, `ingress.host`, `ingress.alb.certificateArn` |
| `deploy/argocd/overlays/<env>/monitoring-patch.yaml` | Grafana host, ACM annotation |
| `infra/terraform/terraform.tfvars` | `project_name`, domain, Route 53 zone |
| `infra/terraform/backend.hcl` | S3 bucket, key, region |
| GitLab CI/CD variables | `TF_STATE_BUCKET`, `AWS_ROLE_ARN`, … |
| [CODEOWNERS](../../CODEOWNERS) | `@YOUR_GITLAB_USER` |

```bash
rg 'your-group|your-repo|example\.com|123456789012|replace-me' --glob '!docs/diagrams/*'
```

---

## Phases

| Phase | Focus | Reference |
|-------|--------|-----------|
| 0 | Prerequisites | [README](README.md) |
| 1 | Terraform (VPC, EKS, IAM, ACM) | [runbook.md §3](runbook.md#3-create-infrastructure) |
| 2 | AWS Load Balancer Controller | [runbook.md §4](runbook.md#4-install-aws-load-balancer-controller-irsa-iam-roles-for-service-account) |
| 3 | Argo CD bootstrap | [runbook.md §5–6](runbook.md#5-bootstrap-argocd) |
| 4 | Overlays + Grafana secret | [runbook.md §7](runbook.md#7-configure-prod-overlays-and-monitoring-secret) |
| 5 | GitOps apply | [runbook.md §8](runbook.md#8-deploy-applications-via-argo-cd-overlay-based) |
| 6 | DNS cutover | [runbook.md §9](runbook.md#9-dns-cutover) |
| 7 | Verification | [runbook.md §10](runbook.md#10-final-verification-checklist) |

---

## Terraform state

1. Create encrypted S3 bucket (versioning recommended).
2. `cp infra/terraform/backend.hcl.example infra/terraform/backend.hcl`
3. Mirror values in GitLab: `TF_STATE_BUCKET`, `TF_STATE_KEY`, `AWS_DEFAULT_REGION`.

```bash
make tf-init
make tf-plan
make tf-apply
```

---

## GitLab CI variables

| Variable | Required for plan/apply |
|----------|-------------------------|
| `TF_STATE_BUCKET` | Yes |
| `AWS_ROLE_ARN` | Yes (OIDC; preferred) |
| `TF_STATE_KEY` | Recommended |
| `TF_STATE_LOCK_TABLE` | Optional |

---

## Steady state

| Change type | Path |
|-------------|------|
| Infrastructure | MR → GitLab plan → manual apply |
| Applications | MR → Argo CD sync |

---

## Teardown

See [runbook.md — Teardown](../onboarding/runbook.md#teardown-uninstall-helm-workloads-before-infrastructure-destroy).

```bash
kubectl delete -k deploy/argocd/overlays/prod --ignore-not-found=true
cd infra/terraform && terraform destroy -auto-approve
```
