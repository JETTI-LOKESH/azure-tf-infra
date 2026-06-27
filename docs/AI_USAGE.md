# AI Tools Usage

## Tools Used

- **GitHub Copilot (Claude)** — Used as the primary AI assistant for scaffolding and code generation

## How AI Was Used

1. **Project Scaffolding** — Generated the initial Terraform module structure, variable definitions, and provider configuration based on the assessment requirements.

2. **Terraform Resource Authoring** — AI helped write the Azure resource definitions (VM, VNet, NSG, Key Vault, monitoring alerts) following Terraform best practices and Azure naming conventions.

3. **CI/CD Pipeline** — Generated the GitHub Actions workflow for Terraform validation, linting, security scanning, and plan output on PRs.

4. **Documentation** — AI assisted in creating the operational runbook, monitoring documentation, and README with clear step-by-step instructions.

5. **Security Review** — Used AI to verify NSG rules follow least-privilege, Key Vault access policies are minimal, and no secrets are hardcoded.

## What Was NOT Delegated to AI

- Architecture decisions (VNet topology, subnet layout, alert thresholds)
- Security posture choices (which ports to expose, CIDR restrictions)
- Operational procedures (escalation matrix, recovery timelines)
- Validation — all generated code was reviewed and tested

## Verification

All Terraform code was validated with:
- `terraform fmt -check`
- `terraform validate`
- `terraform plan` (dry run against Azure)
