# CI Security Scan Findings & Remediation Log

Automated via GitHub Actions (tfsec + Checkov) on every push to `main`. Workflow: `.github/workflows/security-scan.yml`.

## Summary of first scan (2026-09-22)

| Finding | Tool(s) | Severity | Status | Rationale |
|---|---|---|---|---|
| Security groups allow ingress/egress from 0.0.0.0/0 | tfsec | Critical | **Accepted risk** | Intentional design: public web SG requires public HTTP/HTTPS ingress; egress rules enable package updates, SSM connectivity, and outbound API calls. Restricting further would break required functionality. |
| DynamoDB table (state lock) not KMS-encrypted, no point-in-time recovery | tfsec, Checkov | High/Medium | **To remediate** | Genuine gap — low-risk (contains only Terraform lock metadata, no sensitive data) but a fast, cheap fix |
| IAM least-privilege policy uses wildcarded actions (e.g. `ec2:*`) | tfsec, Checkov | High | **Accepted risk (documented trade-off)** | Fully granular action-level scoping (e.g. `ec2:RunInstances`, `ec2:DescribeInstances`, ...) would require enumerating 50+ individual actions per service for a project actively iterating on infrastructure. The policy already removes `AdministratorAccess` entirely and scopes to only the services this project uses — a meaningful improvement over the starting state, with resource-level scoping identified as a natural next iteration. |
| EC2 instance not EBS-optimized, no detailed monitoring | Checkov | Low | **To remediate** | Quick, low-cost improvements |

## Remediation applied

_(updated as fixes are made)_

## Notes

This log itself is intended as a GRC artifact: it demonstrates the "detect → triage → decide → document" cycle expected of a real security/compliance function, rather than treating scanner output as pass/fail noise.
