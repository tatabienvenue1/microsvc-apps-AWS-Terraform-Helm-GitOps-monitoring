# Project plan — Online Boutique on AWS

**Repository:** Production-Grade Microservices Platform on AWS (End-to-End)  
**Application:** [Google Online Boutique / microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo) **v0.10.4**  
**Companion doc:** [design.md](./design.md)  
**Operator guide:** [../onboarding/runbook.md](../onboarding/runbook.md) · [../onboarding/deployment.md](../onboarding/deployment.md)

**Related platform (Azure):** [micser-apps-Azure-Terraform-Helm-GitOps-monitoring](https://github.com/btilki/micser-apps-Azure-Terraform-Helm-GitOps-monitoring) — same Online Boutique workload and platform patterns on AKS with Azure DevOps.

---

## 1. Executive summary

This plan describes **what this AWS repository delivers today**, **how it is operated**, and **how it compares** to the Azure sibling project. The goal is a **production-grade platform**: Terraform provisions EKS and networking; GitLab CI validates infrastructure and applies changes with guardrails; Argo CD deploys the Online Boutique Helm chart and kube-prometheus-stack from Git; TLS terminates on an **Application Load Balancer (ALB)** with **ACM**; observability and evidence screenshots document a working end state.

This document does **not** change runtime behavior. It is the single place for scope, phases, responsibilities, and future work.

---

## 2. Goals and non-goals

### Goals

| # | Goal | How it is met in this repo |
|---|------|----------------------------|
| G1 | Reproducible infrastructure | Terraform modules (VPC, EKS), committed `.terraform.lock.hcl`, S3 remote state |
| G2 | Safe infrastructure changes | GitLab CI: fmt/validate, tfsec, Checkov, Trivy; plan artifact; **manual** apply on protected `main` |
| G3 | GitOps for workloads | Argo CD `Application` + Kustomize overlays (`dev` / `stage` / `prod`) |
| G4 | Production-shaped ingress | ALB Ingress Controller, ACM cert, Route 53 (documented in runbook) |
| G5 | Supply-chain hygiene | Helm: per-service **image digests**, digest-pinned Redis/Busybox |
| G6 | Baseline network hardening | Helm `networkPolicy.*` (default-deny egress + DNS + optional internet HTTPS/HTTP) |
| G7 | Observability | Second Argo app: `kube-prometheus-stack` (Grafana ingress on ALB) |
| G8 | Operational clarity | README runbook, diagrams, this plan + architecture design |

### Non-goals (current)

| Item | Notes |
|------|--------|
| Multi-region active-active | Single region (`eu-central-1` default) |
| Per-environment AWS accounts or EKS clusters | One cluster; envs are **GitOps overlays**, not separate clusters |
| Building custom microservice images | Uses Google sample registry images at fixed release |
| Azure-style **per-env container registry** + `acr import` promotion | AWS repo pins upstream digests in Helm values; no in-repo image build/promote pipelines |
| Service mesh (Istio/Linkerd) | Out of scope |
| Compliance certifications | Out of scope (SOC 2 / ISO not targeted) |
| Full secrets operator (External Secrets / Sealed Secrets) | Grafana admin secret is manual bootstrap (documented) |

---

## 3. Comparison with the Azure project

Both repositories deploy **Online Boutique** with **Terraform + Helm + Argo CD + Prometheus/Grafana**. They differ mainly in **cloud primitives**, **CI system**, and **maturity of mono-repo layout**.

| Dimension | **This repo (AWS)** | **[Azure project](https://github.com/btilki/micser-apps-Azure-Terraform-Helm-GitOps-monitoring)** |
|-----------|---------------------|--------------------------------------------------------------------------------------------------|
| Cloud | AWS (EKS, VPC, ALB, ACM, Route 53, IRSA) | Azure (AKS, VNet, NGINX Ingress, cert-manager, Azure DNS, Workload Identity) |
| CI/CD | **GitLab CI** (`.gitlab-ci.yml`) | **Azure DevOps** (`azure-pipelines.yml`, `pipelines/`) |
| Git hosting | GitLab (documented; placeholders in Argo patches) | GitHub + GitOps PRs from pipelines |
| Infra layout | Single Terraform root: `infra/terraform/` | Bootstrap + shared + per-env stacks under `infra/terraform/` |
| Application packaging | **One Helm chart** for the full stack (`deploy/helm/online-boutique/`) | **Per-service charts** under `charts/` + `apps/` Docker contexts |
| Image source | Google Artifact Registry **v0.10.4**, digest-pinned in values | Mix: owned builds to **per-env ACR** + upstream images; **promote by digest** |
| Environments | Overlays: `deploy/argocd/overlays/{dev,stage,prod}` | Namespaces `dev` / `stage` / `prod` on one AKS cluster |
| Ingress / TLS | ALB + ACM ARN on Ingress annotations | NGINX + cert-manager + Let's Encrypt (DNS-01) |
| State / identity | S3 backend; GitLab **OIDC → IAM role** (preferred) | Azure Storage remote state; Azure DevOps / SP / Key Vault |
| Extra docs | README (runbook-heavy) + **this plan** + **architecture design** | ARCHITECTURE.md, DEPLOYMENT.md, SECURITY.md, ROADMAP.md, phased `docs/implementation/` |
| Policies / quotas | NetworkPolicy pack in Helm chart | `gitops/platform/` quotas, NetPol, Pod Security labels |

**Cross-cloud consistency:** AWS and Azure implementations follow the same platform engineering pattern on two clouds: *IaC foundation → automated validation → GitOps delivery → observability → security baselines*, with documented tradeoffs (single cluster vs per-env registries, upstream images vs owned CI).

---

## 4. Current scope (what is implemented)

### 4.1 Infrastructure (`infra/terraform/`)

| Component | Implementation |
|-----------|----------------|
| Network | `terraform-aws-modules/vpc` — public/private subnets, NAT (single NAT gateway), subnet tags for ELB |
| Kubernetes | `terraform-aws-modules/eks` — managed node group, IRSA, control plane logs, KMS encryption for secrets |
| Ingress IAM | IRSA role + policy for **AWS Load Balancer Controller** |
| TLS (optional) | `acm.tf` — ACM certificate + Route 53 validation when domain + zone variables set |
| CI examples | `policies/gitlab-oidc-trust-policy*.example.json` |

### 4.2 Delivery

| Layer | Path | Behavior |
|-------|------|----------|
| CI | `.gitlab-ci.yml` | **Always:** `terraform:fmt_validate`, `helm:lint`. **On Terraform/CI changes:** tfsec, Checkov, Trivy, `terraform:plan`, manual `terraform:apply` (protected `main`) |
| GitOps | `deploy/argocd/` | `AppProject`, base `Application`s, env patches (repo URL, ingress host, ACM ARN, Grafana host) |
| Workloads | `deploy/helm/online-boutique/` | Full v0.10.4 workloads, ALB Ingress, digests, NetworkPolicies |
| Monitoring | Argo app → `kube-prometheus-stack` | Grafana on ALB; admin secret created outside Git |

### 4.3 Evidence

Screenshots under `docs/diagrams/` (referenced from README): infrastructure diagram, GitLab CI, boutique UI, Argo CD apps, Grafana.

---

## 5. Roles and responsibilities

| Role | Responsibility in this project |
|------|--------------------------------|
| **Platform engineer (you)** | Terraform, CI variables, OIDC trust, bootstrap (LBC, Argo CD, DNS), overlay values |
| **GitLab CI** | Validate IaC and Helm; plan/apply AWS infra when relevant paths change |
| **Argo CD** | Continuous sync of Helm releases from Git (after one-time bootstrap) |
| **AWS** | EKS, ALB, ACM, Route 53, IAM, S3 state |
| **Google (upstream)** | Application container images at pinned release |

---

## 6. Phased delivery model

Phases align with [../onboarding/runbook.md](../onboarding/runbook.md). Use them for **first-time build**, **onboarding**, and **change-management** walkthroughs.

| Phase | Name | Outcome | Primary artifacts |
|-------|------|---------|-------------------|
| 0 | Prerequisites | Tools, AWS auth, domain/zone decisions | Local CLI, `terraform.tfvars`, `backend.hcl` |
| 1 | Terraform foundation | VPC + EKS + outputs + optional ACM | `infra/terraform/`, S3 state |
| 2 | Cluster access + LBC | `kubectl`, AWS Load Balancer Controller with IRSA | Helm install (runbook) |
| 3 | Argo CD bootstrap | Argo CD running; optional ALB for UI | `kubectl apply` stable manifest + Ingress |
| 4 | GitOps apps | Online Boutique + monitoring synced | `deploy/argocd/overlays/<env>` |
| 5 | DNS + TLS cutover | Public HTTPS for shop, Grafana, Argo CD | Route 53 alias records |
| 6 | Steady state | CI for infra; Argo for apps; evidence captured | `.gitlab-ci.yml`, `docs/diagrams/` |
| 7 | Teardown | Workloads removed before `terraform destroy` | README teardown section |

**Hybrid operations (recommended):**

- **Bootstrap once** manually (or scripted) for Argo CD and secrets.
- **Terraform** changes via GitLab CI on `main` with manual apply.
- **Application** changes only in Git; Argo CD reconciles.

---

## 7. CI/CD plan (GitLab)

### 7.1 Pipeline stages

```text
validate → plan → deploy
```

### 7.2 Job matrix

| Job | Stage | Runs when | Purpose |
|-----|-------|-----------|---------|
| `terraform:fmt_validate` | validate | Every pipeline | `terraform fmt -check`, `validate` (no AWS backend) |
| `helm:lint` | validate | Every pipeline | `helm lint` + `helm template` smoke test |
| `tfsec:scan` | validate | `infra/terraform/**` or `.gitlab-ci.yml` changed | Terraform security |
| `checkov:scan` | validate | Same | Policy-as-code |
| `trivy:config_scan` | validate | Same | Misconfig scan (HIGH/CRITICAL) |
| `terraform:plan` | plan | Same | Plan + `tfplan` artifact |
| `terraform:apply` | deploy | Protected `main` + manual + same path rules | Apply saved plan |
| `argocd:sync_hint` | deploy | `main` | Reminder that app sync is GitOps-driven |

### 7.3 Required CI variables (summary)

| Variable | Required for plan/apply |
|----------|-------------------------|
| `TF_STATE_BUCKET` | Yes |
| `AWS_ROLE_ARN` (OIDC) or static AWS keys | Yes |
| `TF_STATE_KEY`, `TF_STATE_LOCK_TABLE`, `AWS_DEFAULT_REGION` | Optional / recommended |

Details: [README — GitLab CI](../README.md#gitlab-ci--aws-credentials-for-terraform).

---

## 8. GitOps plan (Argo CD)

### 8.1 Layout

```text
deploy/argocd/
  project.yaml
  base/
    project.yaml
    online-boutique-application.yaml
    monitoring-application.yaml
  overlays/
    dev|stage|prod/
      kustomization.yaml
      online-boutique-patch.yaml
      monitoring-patch.yaml
```

### 8.2 Before first sync (per environment)

1. Set `spec.source.repoURL` and `targetRevision` in overlay patches.
2. Set `ingress.host` and `ingress.alb.certificateArn` (boutique).
3. Set Grafana host and `certificate-arn` in monitoring patch.
4. Create `grafana-admin-credentials` in namespace `monitoring`.
5. `kubectl apply -f deploy/argocd/project.yaml`
6. `kubectl apply -k deploy/argocd/overlays/<env>`

Checklist: [README — Argo CD overlay edit checklist](../README.md#argocd-overlay-edit-checklist).

---

## 9. Security and compliance plan (pragmatic)

| Control | Status | Location / note |
|---------|--------|----------------|
| No long-lived keys in Git | ✅ | Use GitLab OIDC + IAM role |
| IaC scanning in CI | ✅ | tfsec, Checkov, Trivy (gated) |
| Immutable workload images | ✅ | `values.yaml` digests + `_helpers.tpl` |
| Network egress baseline | ✅ | `networkpolicies.yaml`; tune `allowInternetEgress` |
| Secrets in Git | ⚠️ | Do not commit `terraform.tfvars`, `backend.hcl`; Grafana secret manual |
| EKS API exposure | ⚠️ | Restrict `eks_cluster_endpoint_public_access_cidrs` for real prod |
| Admission policies (Kyverno/Gatekeeper) | ❌ | Future |
| Per-env registry isolation | ❌ | Azure pattern; not in AWS v1 |

---

## 10. Observability plan

| Item | Approach |
|------|----------|
| Metrics / alerts | kube-prometheus-stack via Argo CD |
| Dashboards | Grafana (ingress on ALB) |
| App health | Kubernetes probes; Grafana “apps healthy” evidence |
| Ingress health | ALB target health via `/_healthz` on frontend |

---

## 11. Documentation plan (this effort)

| Document | Purpose |
|----------|---------|
| [README.md](../../README.md) | Entry hub |
| [project-plan.md](./project-plan.md) | This file |
| [design.md](./design.md) | System design, diagrams, ADRs |
| [../onboarding/runbook.md](../onboarding/runbook.md) | Full install runbook |
| [medium-article.md](./medium-article.md) | Medium article draft |

Documentation layout: root `SECURITY.md`, `CHANGELOG.md`, `CODEOWNERS`; `docs/{architecture,onboarding,runbooks,diagrams,incident-response}/` — aligned with senior DevOps repo conventions.

---

## 12. Roadmap

### Current (shipped)

- EKS + VPC Terraform
- GitLab CI validate / plan / manual apply
- Single-chart Online Boutique v0.10.4 with digests + NetworkPolicies
- Argo CD base + dev/stage/prod overlays
- Monitoring stack via Argo CD
- README runbook + evidence
- Fork-ready placeholders in prod overlays

### Next (documentation or platform enhancements)

| Item | Benefit |
|------|---------|
| `SECURITY.md` | Identity, OIDC, secrets, prod checklist |
| `TROUBLESHOOTING.md` | ALB, Argo sync, DNS, CI auth failures |
| External Secrets Operator for Grafana | Close GitOps secrets gap |
| Narrow `allowInternetEgress` to known CIDRs | Stronger NetPol story |
| GitHub Actions mirror (lint only) | Broader CI familiarity |

### Later (parity with Azure depth)

| Item | Notes |
|------|--------|
| Per-service Helm charts + `apps/` builds | Match Azure mono-repo layout |
| Image promotion pipeline (ECR per env) | AWS analogue of `az acr import` |
| App-of-apps / ApplicationSet | Scale GitOps |
| ADRs under `docs/adr/` | Document single-cluster vs multi-account |
| Cost / DR docs | Operational maturity |

---

## 13. Success criteria

Use this checklist before **production go-live** (or handover to an operations team):

- [ ] GitLab pipeline green on `main` (at least validate jobs on a docs-only commit; plan/apply when Terraform changes).
- [ ] `terraform apply` completed once; outputs recorded (`configure_kubectl`, IRSA ARN, ACM ARN).
- [ ] Argo CD applications **Synced** / **Healthy** for boutique + monitoring.
- [ ] HTTPS storefront loads; Grafana and Argo CD URLs documented (even if private).
- [ ] CI guardrails documented (OIDC or path-based jobs) and Helm hardening documented (digests, NetworkPolicy) in [SECURITY.md](../../SECURITY.md).
- [ ] Prod overlay values set to **your** repo URL, domain, and ACM ARN (replace fork placeholders).

---

## 14. Platform overview (onboarding walkthrough)

Standard walkthrough for new platform engineers or stakeholders:

1. **Purpose:** Run Online Boutique on AWS with IaC, CI, GitOps, TLS ingress, and observability — application code remains upstream (Google).
2. **Architecture:** VPC → EKS → ALB → pods; GitLab changes infra; Argo CD changes apps ([design.md](./design.md) diagrams).
3. **Controls:** Digest-pinned Helm chart, NetworkPolicy defaults, IaC scanners in CI ([SECURITY.md](../../SECURITY.md)).
4. **Tradeoffs:** One EKS cluster with logical env overlays — lower cost and complexity than multiple clusters; weaker blast-radius isolation than per-account or per-env registries (see Azure sibling for comparison).
5. **Verification:** Screenshots and checks in [../diagrams/](../diagrams/) and [../onboarding/runbook.md](../onboarding/runbook.md).

---

## 15. References

- [Google microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Argo CD](https://argo-cd.readthedocs.io/)
- [Azure sibling — ARCHITECTURE.md](https://github.com/btilki/micser-apps-Azure-Terraform-Helm-GitOps-monitoring/blob/main/ARCHITECTURE.md)
