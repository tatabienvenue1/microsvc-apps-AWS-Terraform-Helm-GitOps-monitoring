terraform {
  required_version = ">= 1.5.0"

  # Remote state is configured at `terraform init` (see README). Use
  # `terraform init -backend=false` for purely local state without an S3 bucket.
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
