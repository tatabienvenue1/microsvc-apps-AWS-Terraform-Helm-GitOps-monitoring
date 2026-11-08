# Security

Security model for **Online Boutique on AWS**.  
**Deploy:** [docs/onboarding/deployment.md](docs/onboarding/deployment.md) · **Architecture:** [docs/architecture/overview.md](docs/architecture/overview.md) · **Design:** [docs/architecture/design.md](docs/architecture/design.md)

---

## Principles

- **No secrets in Git** — `terraform.tfvars`, `backend.hcl`, credentials in GitLab CI variables only.
- **Immutable images** — digest-pinned Helm values for microservices-demo **v0.10.4**.
- **Network baseline** — default-deny egress NetworkPolicies with explicit allows (`networkPolicy.*` in chart values).
- **Gated infrastructure changes** — manual `terraform:apply` on protected `main`; IaC scanners on Terraform path changes.

---

## Identity and access

| Layer | Controls |
|-------|----------|
| AWS IAM | EKS access; IRSA for AWS Load Balancer Controller; GitLab OIDC role for CI |
| Kubernetes RBAC | EKS access entries; Argo CD AppProject |
| Git + CI | Protected `main`, [CODEOWNERS](CODEOWNERS), MR reviews |

**GitLab OIDC → AWS:** set `AWS_ROLE_ARN`; trust policies in `infra/terraform/policies/gitlab-oidc-trust-policy*.example.json`.

**IRSA (LBC):** annotate controller ServiceAccount with `aws_load_balancer_controller_irsa_role_arn` Terraform output.

Restrict `eks_cluster_endpoint_public_access_cidrs` in production-shaped deployments.

---

## Secrets

| Secret | Store |
|--------|--------|
| Terraform state | S3 (encrypted) |
| CI credentials | GitLab variables (OIDC preferred) |
| Grafana admin | K8s Secret `grafana-admin-credentials` (bootstrap — not in Git) |

---

## Runtime hardening

- Digest-pinned images: `deploy/helm/online-boutique/values.yaml`
- NetworkPolicies: `templates/networkpolicies.yaml`
- Ingress-only storefront (no `LoadBalancer` for frontend-external)
- Container `securityContext` in workloads template

---

## Supply chain

| Control | Tool / location |
|---------|-----------------|
| IaC scan | GitLab: tfsec, Checkov, Trivy (path-gated) |
| Helm validate | `helm:lint` every pipeline; `make helm-lint` locally |
| Image pin | `image.digests` + `_helpers.tpl` |

---

## Reporting vulnerabilities

Report platform repo issues **privately** to the repository owner. For the Online Boutique application, use [upstream disclosure](https://github.com/GoogleCloudPlatform/microservices-demo).
