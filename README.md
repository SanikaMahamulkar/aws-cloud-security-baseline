# AWS Cloud Security Baseline & Detection Lab

A hands-on AWS security engineering project: building a hardened, monitored cloud environment from scratch using Infrastructure as Code, then validating its defenses against simulated attacker behaviour.

## Status: In Progress

This project is being built incrementally with a full commit history documenting each stage.

## What this project demonstrates

- Infrastructure as Code (Terraform) with remote state management
- AWS account security fundamentals (MFA, least-privilege IAM)
- Cloud security architecture: networking, logging, encryption, threat detection
- Customer-managed KMS encryption with automatic key rotation
- Continuous compliance monitoring (AWS Config) mapped to ISO 27001-relevant controls
- Systematic troubleshooting and diagnosis of cloud networking/access issues
- Simulated attack scenarios mapped to MITRE ATT&CK, with measured detection coverage

## Tech stack

- **IaC:** Terraform, AWS provider
- **State management:** S3 (versioned, KMS-encrypted) + DynamoDB (locking)
- **Cloud:** AWS (eu-west-2 / London)
- **Networking:** VPC, public/private subnets across 2 AZs
- **Logging:** Multi-region CloudTrail with log file validation, KMS-encrypted
- **Detection:** GuardDuty (S3 protection, malware protection)
- **Compliance:** AWS Config (S3 public access, SSH exposure, encryption, IAM password policy, CloudTrail status)
- **Encryption:** Customer-managed KMS key with automatic yearly rotation, applied across all S3 buckets
- **Compute:** EC2 (private subnet, encrypted, IMDSv2 enforced)
- **Automated response:** Lambda function triggered by EventBridge on GuardDuty findings, publishes alerts via SNS
- **Planned:** Security Hub

## Architecture

_(Diagram to be added as infrastructure is built out)_

## Progress log

- [x] AWS account hardened: root MFA enabled, dedicated IAM admin user
- [x] Terraform initialized with remote state backend (S3 + DynamoDB state locking)
- [x] VPC with public/private subnets across 2 Availability Zones
- [x] Multi-region CloudTrail with encrypted, validated logging
- [x] GuardDuty threat detection enabled
- [x] Security groups: public web, private internal, IP-restricted SSH
- [x] Least-privilege IAM policy attached and validated — AdministratorAccess fully removed from sanika-admin; confirmed via terraform plan running clean across all 40+ resources with zero excess permissions
- [x] EC2 target instance deployed (private subnet, encrypted, IMDSv2)
- [x] VPC interface endpoints for SSM provisioned (IAM role, security groups, endpoints all verified correct via CLI)
- [x] AWS Config enabled with 5 compliance rules (S3 public access, SSH exposure, EBS encryption, IAM password policy, CloudTrail status)
- [x] Customer-managed KMS key with automatic rotation; all S3 buckets migrated from AES256 to KMS encryption
- [x] Automated incident response: GuardDuty findings routed via EventBridge to Lambda, which publishes formatted alerts to SNS — pipeline validated via direct Lambda invocation (SNS alert confirmed delivered)
- [x] GuardDuty populated with 400 sample findings across multiple attack categories for detection coverage analysis
- [x] Detection coverage mapped to MITRE ATT&CK tactics — see `detection-coverage-report.md` (8 tactics, 212 distinct finding types, severity distribution)
- [x] SSM Session Manager fully resolved — root cause identified (AMI did not ship amazon-ssm-agent pre-installed); fixed via user_data agent install; confirmed working via remote command execution (see Known Issues below for full root-cause writeup)
- [ ] Attack simulation (Atomic Red Team / manual, mapped to MITRE ATT&CK)
- [ ] Automated response (Lambda + SNS)
- [ ] Full security report and threat model

## Known Issues (Resolved)

**SSM Session Manager registration failure — RESOLVED.** Root cause: the Amazon Linux 2023 AMI used for the target instance does not ship with the `amazon-ssm-agent` service pre-installed. The original `user_data` script only attempted to `systemctl enable/start amazon-ssm-agent`, which silently failed (`Unit file amazon-ssm-agent.service does not exist`) — visible only via `aws ec2 get-console-output`, which had not been checked closely enough in earlier debugging passes. All previously-verified infrastructure (IAM instance profile, VPC endpoints, security groups, DNS settings) was genuinely correct throughout; the fault was entirely at the OS/agent level, not the network/IAM level. Fixed by adding an explicit `dnf install` of the official `amazon-ssm-agent.rpm` to `user_data` before enabling the service. Confirmed resolved: the instance now registers as `Online` in `aws ssm describe-instance-information`, and a real remote command (`aws ssm send-command`) was executed successfully with genuine output returned. This is a useful reminder that a fully-correct network/IAM configuration can still mask a simple missing-dependency issue at the OS layer — the eventual fix required reading console boot logs directly rather than continuing to re-verify networking that was already confirmed correct.

## Author

Sanika Mahamulkar — MSc Cybersecurity, University of Bristol
