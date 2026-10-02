# Terraform plan and apply through GitHub Actions

## Flow

Pull requests run Terraform formatting and static validation without AWS credentials. After a change is merged to `main`, GitHub Actions assumes the plan role through OIDC, reads the dev state, builds a plan, and stores the binary plan in the private state bucket. The workflow summary lists resource addresses and actions without printing the complete plan values into the public Actions log.

The apply job waits for approval in the `infra-apply` GitHub Environment. After approval, it assumes a separate apply role, downloads the exact plan for that commit, and applies it. Once AWS authentication succeeds, cleanup deletes the plan object even if apply fails. Recovery therefore requires a fresh plan, not a retry of only the apply job. A lifecycle rule expires leftover plan objects and their noncurrent S3 versions after seven days.

The plan role is trusted only for the immutable `main` branch subject. The apply role is trusted only for the `infra-apply` environment subject. Both roles use short-lived STS credentials; neither role uses stored AWS access keys.

## Why there are two roles

The plan role can inspect EC2, EKS, and IAM resources and read the dev state. Terraform's S3 backend also needs to create and delete its `.tflock` object while planning, so “read-only plan” means no infrastructure mutations, not literally zero writes. It can write a plan object to the dedicated `orderflow/dev/plans/` prefix.

The apply role has the same refresh access plus scoped state writes, EKS and VPC mutation actions, and `iam:PassRole` limited to the three `orderflow-dev-*` roles and the EKS service. Some EC2/EKS APIs require `Resource: "*"`; those actions are kept to the services used by this stack. Re-check policy findings and actual denied API calls when the module grows.

## One-time setup

The OIDC provider and its two IAM roles are a bootstrap dependency: GitHub cannot assume a role before AWS has that role and provider. Initialize and review the bootstrap plan using the existing `eks-lab` profile, then apply the IAM-only bootstrap locally. This creates no cluster or NAT gateway. The S3 plan-file expiry rule is a separate change to the state-backend bootstrap root.

Before merging the deployment workflow, configure these repository variables:

- `TF_STATE_BUCKET`
- `AWS_TERRAFORM_PLAN_ROLE_ARN`
- `AWS_TERRAFORM_APPLY_ROLE_ARN`

Configure these repository secrets because they contain operator-specific values that should not appear in public workflow logs:

- `TF_VAR_OPERATOR_PUBLIC_CIDR` — the operator's current public IPv4 address with `/32`
- `TF_VAR_CLUSTER_ADMIN_PRINCIPAL_ARN` — the IAM principal Terraform grants Kubernetes cluster-admin access

The `infra-apply` environment must be restricted to the `main` branch and require a deployment approval. This repository currently has one reviewer; that gives a deliberate manual stop before apply, but it is not an independent four-eyes review.

## Reviewing a run

1. On the Actions run, confirm static validation passed.
2. Review the Terraform plan summary: resource addresses and `create`, `update`, or `delete` actions.
3. Inspect the deployment job and approve only when the plan is expected and the AWS cost window is acceptable.
4. Confirm the apply job succeeded. If it fails, diagnose the first denied AWS API or Terraform error before retrying.

The plan file is tied to the commit SHA. If the remote state changes before apply, Terraform rejects a stale plan; rerun the workflow to create and review a fresh plan.

## Common failures

- **`Not authorized to perform sts:AssumeRoleWithWebIdentity`:** compare the GitHub token subject with the role trust policy. The plan role expects the exact `main` subject; the apply role expects the exact `infra-apply` environment subject.
- **S3 `AccessDenied`:** check the state bucket variable, state key, `.tflock` permissions, and plan prefix. The GitHub role policies intentionally limit S3 access to the dev state and plan objects.
- **Terraform reports a missing variable:** refresh the two repository secrets; the EKS API allow-list uses the operator's current `/32` address.
- **`Saved plan is stale`:** do not force it. Generate a fresh plan and review that one.
- **IAM role `AccessDenied` during refresh or replacement:** Terraform calls `ListRolePolicies` to inspect inline policies and `ListInstanceProfilesForRole` before deleting a role, even if both lists are empty. Plan and apply share the same IAM read actions, scoped to the three OrderFlow EKS roles. Inspect the denied API and its resource scope before changing permissions.
- **Node group creation cannot validate its service-linked role:** `CreateNodegroup` can fail with an `InvalidRequestException` mentioning `iam:GetRole` even though the caller has EKS create permissions. The apply role must also read the AWS-owned EKS service-linked roles; these have different ARNs from the three project roles. The policy grants scoped reads and conditional creation for the two EKS services.
- **A fresh plan replaces roles after a failed create:** Terraform may have created the AWS roles but marked their state as tainted when a later provider read failed. Check both AWS and Terraform state; replacement can be expected for those incomplete creations. Regenerate the plan after fixing the failure rather than removing resources from state.
- **A workflow waits at `infra-apply`:** this is the expected deployment gate; review the plan summary before approving.

The first real EKS apply is still billable. The environment approval is the cost-control checkpoint; Terraform plans and IAM/OIDC setup alone do not create EKS worker nodes.
