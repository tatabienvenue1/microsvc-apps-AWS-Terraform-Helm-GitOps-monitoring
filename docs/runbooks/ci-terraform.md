# Runbook: GitLab CI and Terraform

## GitLab CI — no AWS credentials

**Symptoms:** Pipeline fails in `terraform:plan` / `apply` with authentication error.

**Fix:**

1. Set GitLab variable `AWS_ROLE_ARN` (preferred).
2. Configure IAM trust: `infra/terraform/policies/gitlab-oidc-trust-policy.example.json`.
3. Fallback: `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` (masked, protected).

## TF_STATE_BUCKET required

Set `TF_STATE_BUCKET` in GitLab CI/CD variables. Match `infra/terraform/backend.hcl`.

## Plan job did not run

Jobs are **path-gated** to `infra/terraform/**` and `.gitlab-ci.yml`. For Helm-only changes, run locally:

```bash
make tf-plan
```

## OIDC assume role fails

- Trust policy `aud` must include `https://gitlab.com`.
- `gitlab.com:sub` must match your project path (see protected example JSON).

## Terraform state / duplicate resources

Use one backend everywhere (local `backend.hcl` = GitLab `TF_STATE_*`). Never delete the state bucket before `terraform destroy`.
