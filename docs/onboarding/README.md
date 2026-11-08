# Onboarding

Get from **zero** to a running Online Boutique on EKS.

| Step | Document |
|------|----------|
| 1. Prerequisites & fork setup | [deployment.md](deployment.md) |
| 2. Full command-by-command runbook | [runbook.md](runbook.md) |
| 3. Local shortcuts | [Makefile](../../Makefile) (`make help`) |

**Architecture:** [../architecture/overview.md](../architecture/overview.md)  
**Troubleshooting:** [../runbooks/troubleshooting.md](../runbooks/troubleshooting.md)

---

## Prerequisites (summary)

| Tool | Version |
|------|---------|
| Terraform | ≥ 1.5 |
| AWS CLI | v2 |
| kubectl | current |
| Helm | 3 |
| Git | any recent |

```bash
terraform version && aws --version && kubectl version --client && helm version
aws sts get-caller-identity
```

---

## Quick path

```bash
git clone <your-repo-url>
cd <repo-root>
cp infra/terraform/terraform.tfvars.example infra/terraform/terraform.tfvars
cp infra/terraform/backend.hcl.example infra/terraform/backend.hcl
# edit tfvars + backend.hcl; set GitLab CI variables (see runbook)
make tf-init && make tf-plan && make tf-apply
make kubeconfig
# bootstrap LBC, Argo CD, secrets — see runbook.md
make argo-apply ARGO_OVERLAY=prod
```

Estimated time: **45–90 minutes** including DNS/ALB waits.
