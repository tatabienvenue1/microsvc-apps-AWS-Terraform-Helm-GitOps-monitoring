# Changelog

All notable changes to this **platform repository** (IaC, CI, GitOps, Helm) are documented here.  
Application release remains pinned to [Google Online Boutique v0.10.4](https://github.com/GoogleCloudPlatform/microservices-demo).

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [1.0.0] - 2026-05

### Added

- Terraform foundation: VPC, EKS, IRSA for AWS Load Balancer Controller, optional ACM
- GitLab CI: fmt/validate, Helm lint, tfsec, Checkov, Trivy; path-gated plan/apply
- Argo CD GitOps with dev/stage/prod overlays; kube-prometheus-stack monitoring
- Helm chart for Online Boutique with digest-pinned images and NetworkPolicy egress baseline
- Documentation: architecture, onboarding runbook, operational runbooks, incident response
- Root governance: Makefile, SECURITY.md, CODEOWNERS, pre-commit hooks
