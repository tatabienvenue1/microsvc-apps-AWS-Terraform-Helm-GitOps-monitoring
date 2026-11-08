# Platform engineering shortcuts — Online Boutique on AWS
# Requires: terraform, aws, kubectl, helm (see docs/onboarding/README.md)

TF_DIR       := infra/terraform
HELM_CHART   := deploy/helm/online-boutique
ARGO_OVERLAY ?= prod

.PHONY: help fmt validate helm-lint tf-init tf-plan tf-apply kubeconfig

help:
	@echo "Targets:"
	@echo "  fmt          - terraform fmt -recursive"
	@echo "  validate     - terraform init -backend=false && terraform validate"
	@echo "  helm-lint    - helm lint + template smoke test"
	@echo "  tf-init      - terraform init -backend-config=backend.hcl (local)"
	@echo "  tf-plan      - terraform plan"
	@echo "  tf-apply     - terraform apply"
	@echo "  kubeconfig   - aws eks update-kubeconfig from terraform outputs"
	@echo "  argo-apply   - kubectl apply Argo CD overlay (ARGO_OVERLAY=$(ARGO_OVERLAY))"

fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive

validate:
	terraform -chdir=$(TF_DIR) init -input=false -backend=false
	terraform -chdir=$(TF_DIR) validate

helm-lint:
	helm lint $(HELM_CHART)
	helm template online-boutique $(HELM_CHART) \
		--set ingress.host=boutique.example.com \
		--set ingress.alb.certificateArn=arn:aws:acm:eu-central-1:111111111111:certificate/00000000-0000-0000-0000-000000000000 \
		>/dev/null

tf-init:
	terraform -chdir=$(TF_DIR) init -backend-config=backend.hcl

tf-plan:
	terraform -chdir=$(TF_DIR) plan

tf-apply:
	terraform -chdir=$(TF_DIR) apply

kubeconfig:
	aws eks update-kubeconfig \
		--region "$$(terraform -chdir=$(TF_DIR) output -raw aws_region)" \
		--name "$$(terraform -chdir=$(TF_DIR) output -raw cluster_name)"

argo-apply:
	kubectl apply -f deploy/argocd/project.yaml
	kubectl apply -k deploy/argocd/overlays/$(ARGO_OVERLAY)
