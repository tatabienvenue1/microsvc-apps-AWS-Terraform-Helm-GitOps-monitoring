# Incident response

Lightweight template for **non-production** environments. Adapt for your organization before production use.

---

## Severity levels

| Level | Example | Response |
|-------|---------|----------|
| **SEV1** | Storefront down, all users affected | Immediate investigation; consider rollback |
| **SEV2** | Degraded (errors, single service) | Investigate within 1 hour |
| **SEV3** | Non-user-facing (CI, monitoring gap) | Next business day |

---

## First 15 minutes

1. **Confirm impact** — `curl -I https://boutique.<domain>`, Argo CD UI, Grafana.
2. **Check recent changes** — last GitLab pipeline, last Argo sync, last Terraform apply.
3. **Cluster health** — `kubectl get nodes`, `kubectl get pods -A | grep -v Running`.
4. **Ingress / ALB** — [../runbooks/ingress-alb.md](../runbooks/ingress-alb.md).
5. **GitOps** — [../runbooks/argocd-gitops.md](../runbooks/argocd-gitops.md).

---

## Rollback options

| Layer | Action |
|-------|--------|
| Application | Revert Git commit; Argo CD sync (or rollback in Argo UI) |
| Helm values | Restore previous digest/tag in `values.yaml` / overlay |
| Infrastructure | Revert Terraform MR; `terraform plan` before apply |

Document last-known-good in Git tags or CHANGELOG.

---

## Communication template

```text
Subject: [SEV<n>] Online Boutique AWS — <short summary>

Impact: <who/what>
Start: <UTC time>
Status: Investigating | Mitigated | Resolved
Actions: <bullet list>
Next update: <time>
```

---

## Escalation

- Platform owner: see [CODEOWNERS](../../CODEOWNERS)
- Security issues: [SECURITY.md](../../SECURITY.md) — private report, not public issues with exploit details

---

## Post-incident

- [ ] Timeline and root cause
- [ ] Update [../runbooks/troubleshooting.md](../runbooks/troubleshooting.md) if new symptom
- [ ] Entry in [CHANGELOG.md](../../CHANGELOG.md) if repo/process change
