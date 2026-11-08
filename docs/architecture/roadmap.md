# Roadmap

**Deploy:** [../onboarding/deployment.md](../onboarding/deployment.md) · **Plan:** [project-plan.md](project-plan.md)

---

## Current (v1)

| Area | Status |
|------|--------|
| Terraform VPC + EKS + LBC IRSA + optional ACM | Done |
| GitLab CI validate / plan / manual apply | Done |
| Helm chart v0.10.4 + digests + NetworkPolicies | Done |
| Argo CD overlays (dev/stage/prod) | Done |
| Monitoring stack | Done |
| Senior doc layout + Makefile / pre-commit | Done |

---

## Next

| Item | Notes |
|------|--------|
| External Secrets for Grafana | Close secrets-in-Git gap |
| `docs/runbooks/` deep dives | ALB, Argo, DNS, CI auth |
| Pin Argo CD install version | Reproducible bootstrap |
| Tighter NetworkPolicy egress | Replace broad internet allow |

---

## Later

| Item | Notes |
|------|--------|
| Per-service charts + ECR promotion | Parity with [Azure repo](https://github.com/btilki/micser-apps-Azure-Terraform-Helm-GitOps-monitoring) |
| ApplicationSet / app-of-apps | Scale GitOps |
| ADRs under `docs/architecture/adr/` | Extract from [design.md](design.md) |
| Cost / DR documentation | `docs/architecture/cost/`, disaster recovery |

---

## Non-goals

- Multi-region active-active
- Service mesh in v1
- Compliance certifications
- Custom business logic in Online Boutique
