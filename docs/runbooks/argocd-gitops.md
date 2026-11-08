# Runbook: Argo CD and GitOps

## Application OutOfSync / Unknown

```bash
kubectl describe application -n argocd online-boutique
kubectl describe application -n argocd monitoring
```

Check:

- `spec.source.repoURL` and `path: deploy/helm/online-boutique`
- Private repo: Argo CD repository credentials configured
- Helm parameters in overlay patches (host, ACM ARN)

## Monitoring app fails — Grafana secret

Create before sync:

```bash
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl -n monitoring create secret generic grafana-admin-credentials \
  --from-literal=admin-user=admin \
  --from-literal=admin-password='REPLACE_WITH_STRONG_PASSWORD' \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Apply overlay

```bash
kubectl apply -f deploy/argocd/project.yaml
kubectl apply -k deploy/argocd/overlays/prod
kubectl get applications -n argocd
```

Or: `make argo-apply ARGO_OVERLAY=prod`

## Steady state

Prefer Git revert over `kubectl edit` for production paths. Argo automated sync will reconcile.
