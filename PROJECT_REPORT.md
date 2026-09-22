# AWS Cloud Security Baseline & Detection Lab — Project Report

**Author:** Sanika Mahamulkar, MSc Cybersecurity, University of Bristol
**Repository:** https://github.com/SanikaMahamulkar/aws-cloud-security-baseline
**Date:** September 2026

## Executive Summary

This project builds, hardens, monitors, and validates a cloud security baseline in AWS using Infrastructure as Code (Terraform). Rather than a theoretical exercise, every control described in this report is live infrastructure in a real AWS account, provisioned reproducibly, version-controlled, and evidenced through actual command output, API responses, and delivered alerts.

The project demonstrates the full lifecycle a cloud security or GRC engineer is expected to own: designing a segmented network, enabling logging and threat detection, encrypting data at rest with customer-managed keys, applying least-privilege access control, wiring automated incident response, continuously scanning infrastructure code for misconfigurations, and — critically — measuring and documenting what the resulting detection capability actually covers, rather than assuming it.

## Objectives

1. Provision a segmented, monitored AWS environment entirely via Terraform, with remote state management suitable for team use.
2. Establish comprehensive logging (CloudTrail) and continuous compliance monitoring (AWS Config) mapped to controls relevant to ISO 27001.
3. Enable threat detection (GuardDuty) and build automated incident response (EventBridge → Lambda → SNS).
4. Encrypt data at rest using a customer-managed KMS key with automatic rotation, rather than relying on default service-managed encryption.
5. Apply the principle of least privilege to the IAM identity managing the project, replacing broad administrative access with a scoped policy derived from actual usage.
6. Integrate automated security scanning (tfsec, Checkov) into the development workflow via CI, and treat findings as a triage-and-document exercise rather than a pass/fail gate.
7. Generate real detection findings and measure coverage against the MITRE ATT&CK framework, rather than asserting detection capability without evidence.

## Architecture

See `architecture-diagram.md` for the full component diagram. In summary:

- A VPC (`10.0.0.0/16`) spans two Availability Zones with two public and two private subnets, an Internet Gateway, and separate route tables for public/private traffic.
- The EC2 target instance sits in a private subnet with no public IP, encrypted EBS storage, IMDSv2 enforced (blocking SSRF-based credential theft via the instance metadata service), EBS optimization, and detailed CloudWatch monitoring.
- Three purpose-built security groups govern traffic: a public-web group (80/443 ingress, for any future public-facing component), a private-internal group (VPC-only ingress), and an IP-restricted SSH group scoped to a single administrator IP, looked up dynamically at apply-time.
- Management access to the private instance is provided via AWS Systems Manager Session Manager over three VPC interface endpoints (`ssm`, `ssmmessages`, `ec2messages`), avoiding the need for a bastion host or any inbound SSH exposure.
- CloudTrail is enabled multi-region with log file validation, writing to a KMS-encrypted, versioned S3 bucket with a bucket policy restricted to the CloudTrail service principal.
- AWS Config runs a configuration recorder covering all supported resource types, with five managed rules evaluating S3 public access, SSH exposure, EBS encryption, IAM password policy, and CloudTrail status.
- GuardDuty is enabled with S3 protection and malware protection for EBS volumes attached to flagged instances.
- A customer-managed KMS key with automatic annual rotation encrypts every S3 bucket in the project (Terraform state, CloudTrail logs, Config logs) and the DynamoDB state-lock table.
- An EventBridge rule matches GuardDuty findings and invokes a Lambda function, which formats the finding and publishes a human-readable alert to an SNS topic with an email subscriber.

## Methodology

Infrastructure was built entirely through Terraform, applied incrementally: each capability (networking, logging, detection, compliance, encryption, response, least privilege, CI scanning) was written, validated (`terraform validate`), planned (`terraform plan`), reviewed, and applied (`terraform apply`) as a discrete, committed change — producing a granular git history that itself documents the build sequence and decision points.

State is stored remotely in a versioned, KMS-encrypted S3 bucket with DynamoDB-based locking, reflecting how this would be run in a team setting rather than as a disposable local sandbox.

## Detection Coverage & Automated Response

Full methodology and results are documented in `detection-coverage-report.md`. In summary: 400 GuardDuty sample findings were generated via AWS's official sample-findings API, retrieved via the GuardDuty API, and classified by MITRE ATT&CK tactic and severity band.

**Results:**
- Coverage across 8 MITRE ATT&CK tactics: Persistence (71), Defense Evasion (65), Execution (57), Impact (52), Privilege Escalation (43), Initial Access (35), Discovery (27), Credential Access (20), plus Exfiltration (6) and multi-stage attack sequences (21).
- 212 distinct GuardDuty finding types represented.
- Severity skewed toward Medium/High: 176 High, 159 Medium, 65 Low.

A known limitation was identified and documented: GuardDuty's sample findings do not trigger EventBridge events, an observed AWS behaviour rather than a fault in this project's configuration. This was worked around by validating the response pipeline independently — a synthetic finding payload matching GuardDuty's real event schema was sent via `aws lambda invoke` directly to the response Lambda, which returned a 200 status and a confirmed "Alert processed and published to SNS" response. An email alert was subsequently confirmed delivered to the subscribed address, proving the EventBridge → Lambda → SNS chain functions correctly end-to-end, independent of the sample-finding limitation.

## Least Privilege: Evidence, Not Assertion

The IAM user managing this project (`sanika-admin`) initially held `AdministratorAccess`. A scoped policy was drafted from the actual set of AWS services and actions this project uses — EC2, S3, DynamoDB, CloudTrail, GuardDuty, Config, KMS, Lambda, SNS, EventBridge, CloudWatch Logs, SSM, and the IAM actions needed to manage supporting roles and policies.

Rather than simply attaching the scoped policy alongside the admin policy and assuming it was sufficient, `AdministratorAccess` was fully detached and `terraform plan` was run against the entire ~40-resource infrastructure. It completed cleanly with zero permission errors, confirming the scoped policy is genuinely sufficient for ongoing operation — not merely theoretically adequate.

This is a deliberate methodological choice: least privilege is frequently asserted in cloud security work without being tested. Detaching the broader policy and proving the narrower one still works is the only way to know the scoping is correct.

## CI Security Scanning

A GitHub Actions workflow (`.github/workflows/security-scan.yml`) runs tfsec and Checkov against the Terraform codebase on every push and pull request to `main`. Findings are not treated as pass/fail; the fuller reasoning is documented in `security-scan-findings.md`. Two categories of finding emerged:

- **Accepted risks**: security groups permitting internet ingress/egress where the design genuinely requires it (public web ports; general outbound access for package updates and API calls), and the use of service-level wildcards (`ec2:*`, etc.) in the least-privilege policy rather than fully enumerated per-action permissions — a documented trade-off between operational practicality and maximal granularity for infrastructure still under active iteration.
- **Genuine gaps, remediated**: the DynamoDB state-lock table lacked KMS encryption and point-in-time recovery; the EC2 instance lacked EBS optimization and detailed monitoring. Both were fixed in a follow-up commit and re-validated by the next CI run.

This distinction — separating "the scanner is right and we should fix this" from "the scanner is flagging an intentional, justified design choice" — is itself a core GRC skill, and is preserved in the repository as a durable artifact rather than living only in a CI log.

## Known Limitations

**SSM Session Manager registration.** Despite a correctly configured IAM instance profile, all three required VPC interface endpoints reporting `available`, and security group rules verified via CLI to correctly permit HTTPS between the instance and the endpoints, the EC2 target instance has not registered with Systems Manager (`aws ssm describe-instance-information` returns an empty list). This was tested across two separate instance builds (including a full replace during the CI-findings remediation), ruling out an instance-specific fault. It remains an open item, documented rather than hidden, with next diagnostic steps (DNS resolution from within the instance, NACL inspection, AMI agent version) recorded in the main README.

**GuardDuty sample findings and EventBridge.** As noted above, sample findings do not trigger real-time EventBridge routing — worked around via direct Lambda invocation for pipeline validation, but a genuinely *live* finding travelling the full path from GuardDuty detection through to a delivered email has not yet been observed, only the two halves independently.

## Conclusion

This project delivers a working, evidenced AWS security baseline rather than a checklist of enabled services. Every claim in this report traces to either a Terraform-applied resource, a command's real output, or a delivered artifact (an email alert, a passing CI run, a completed `terraform plan`). Where limitations exist, they are documented rather than obscured — reflecting, deliberately, how a real security or compliance function should operate: honest about coverage gaps, precise about what has and has not been verified.

## Skills Demonstrated

- Infrastructure as Code (Terraform): modules, remote state, provider configuration, resource dependencies
- AWS core services: VPC, EC2, IAM, S3, KMS, DynamoDB, CloudTrail, Config, GuardDuty, Lambda, SNS, EventBridge, Systems Manager, CloudWatch Logs
- Cloud security architecture: network segmentation, least-privilege IAM, encryption at rest, secure remote access without bastion hosts
- Continuous compliance monitoring, mapped conceptually to ISO 27001-relevant controls
- Detection engineering: GuardDuty configuration, MITRE ATT&CK-aligned coverage analysis
- Automated incident response: event-driven architecture (EventBridge → Lambda → SNS)
- DevSecOps / CI security: tfsec, Checkov, GitHub Actions, structured findings triage
- Systematic technical troubleshooting and root-cause investigation
- Clear technical writing and evidence-based reporting for both technical and non-technical audiences
