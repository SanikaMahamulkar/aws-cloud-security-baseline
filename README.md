# AWS Cloud Security Baseline & Detection Lab

A hands-on AWS security engineering project: building a hardened, monitored cloud environment from scratch using Infrastructure as Code, then validating its defenses against simulated attacker behaviour.

## Status: In Progress

This project is being built incrementally with a full commit history documenting each stage.

## What this project demonstrates

- Infrastructure as Code (Terraform) with remote state management
- AWS account security fundamentals (MFA, least-privilege IAM)
- Cloud security architecture: networking, logging, encryption, threat detection
- Simulated attack scenarios mapped to MITRE ATT&CK, with measured detection coverage

## Tech stack

- **IaC:** Terraform, AWS provider
- **State management:** S3 (versioned, encrypted) + DynamoDB (locking)
- **Cloud:** AWS (eu-west-2 / London)
- **Networking:** VPC, public/private subnets across 2 AZs
- **Logging:** Multi-region CloudTrail with log file validation
- **Detection:** GuardDuty (S3 protection, malware protection)
- **Planned:** Security Hub, AWS Config, KMS, Lambda automated response

## Architecture

_(Diagram to be added as infrastructure is built out)_

## Progress log

- [x] AWS account hardened: root MFA enabled, dedicated least-privilege-bound IAM admin user
- [x] Terraform initialized with remote state backend (S3 + DynamoDB state locking)
- [x] VPC with public/private subnets across 2 Availability Zones
- [x] Multi-region CloudTrail with encrypted, validated logging
- [x] GuardDuty threat detection enabled
- [ ] Security groups and network hardening
- [ ] IAM least-privilege policies (replacing initial AdministratorAccess)
- [ ] AWS Config for compliance monitoring
- [ ] Attack simulation (Atomic Red Team / manual, mapped to MITRE ATT&CK)
- [ ] Automated response (Lambda + SNS)
- [ ] Full security report and threat model

## Author

Sanika Mahamulkar — MSc Cybersecurity, University of Bristol
