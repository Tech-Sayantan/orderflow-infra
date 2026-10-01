# OrderFlow Infrastructure

Terraform infrastructure for the OrderFlow DevOps learning project. This is an evolving portfolio lab, not a claim of production readiness. It is designed to practice reusable Terraform modules, AWS networking, EKS IAM, remote state, and reviewable infrastructure changes.

## Repository layout

- `bootstrap/state-backend/` creates the S3 bucket used for Terraform state.
- `modules/vpc/` defines the VPC and subnet/network building blocks.
- `modules/eks/` defines the EKS cluster, node group, IAM, and access configuration.
- `environments/dev/` composes those modules for the development environment.

## Terraform state backend

The S3 backend uses a partial configuration so account-specific bucket details are not committed. After bootstrapping a state bucket, copy `environments/dev/backend.example.hcl` to `environments/dev/backend.hcl`, replace the bucket value, and keep that local file untracked.

```sh
cd environments/dev
cp backend.example.hcl backend.hcl
# Edit backend.hcl with your own bucket name.
terraform init -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan
```

Provide the required `operator_public_cidr` and `cluster_admin_principal_arn` variables locally (for example through an ignored `terraform.tfvars` file). Restrict the EKS API CIDR to your current public IP as a `/32`; do not commit personal IPs, credentials, `.tfstate`, plans, or local variable files.

## Cost and safety

A Terraform plan is a proposal, not proof that AWS resources exist. Review every plan before applying. EKS, NAT gateways, load balancers, and managed databases can incur charges while idle. Use a dedicated learning account, a billing alert, minimal capacity, and verify teardown/state before ending a lab.

## Current scope

The repository currently contains reusable VPC and EKS modules plus a dev environment composition. CI, environment promotion, and additional production controls are planned as the project progresses; they are not represented as complete here.
