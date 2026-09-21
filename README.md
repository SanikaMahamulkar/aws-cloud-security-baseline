# AWS Cloud Security Baseline & Detection Lab

A hands-on AWS security engineering project: building a hardened, monitored cloud environment from scratch using Infrastructure as Code, then validating its defenses against simulated attacker behaviour.

## Status: In Progress

This project is being built incrementally with a full commit history documenting each stage.

## What this project demonstrates

- Infrastructure as Code (Terraform) with remote state management
- AWS account security fundamentals (MFA, least-privilege IAM)
- Cloud security architecture: networking, logging, encryption, threat detection
- Continuous compliance monitoring (AWS Config) mapped to ISO 27001-relevant controls
- Systematic troubleshooting and diagnosis of cloud networking/access issues
- Simulated attack scenarios mapped to MITRE ATT&CK, with measured detection coverage

## Tech stack

- **IaC:** Terraform, AWS provider
- **State management:** S3 (versioned, encrypted) + DynamoDB (locking)
- **Cloud:** AWS (eu-west-2 / London)
- **Networking:** VPC, public/private subnets across 2 AZs
- **Logging:** Multi-region CloudTrail with log file validation
- **Detection:** GuardDuty (S3 protection, malware protection)
- **Compliance:** AWS Config (S3 public access, SSH exposure, encryption, IAM password policy, CloudTrail status)
- **Compute:** EC2 (private subnet, encrypted, IMDSv2 enforced)
- **Planned:** Security Hub, KMS, Lambda automated response

## Architecture

_(Diagram to be added as infrastructure is built out)_

## Progress log

- [x] AWS account hardened: root MFA enabled, dedicated IAM admin user
- [x] Terraform initialized with remote state backend (S3 + DynamoDB state locking)
- [x] VPC with public/private subnets across 2 Availability Zones
- [x] Multi-region CloudTrail with encrypted, validated logging
- [x] GuardDuty threat detection enabled
- [x] Security groups: public web, private internal, IP-restricted SSH
- [x] Least-privilege IAM policy drafted from Access Advisor evidence (pending attachment)
- [x] EC2 target instance deployed (private subnet, encrypted, IMDSv2)
- [x] VPC interface endpoints for SSM provisioned (IAM role, security groups, endpoints all verified correct via CLI)
- [x] AWS Config enabled with 5 compliance rules (S3 public access, SSH exposure, EBS encryption, IAM password policy, CloudTrail status)
- [ ] **Known issue:** SSM Session Manager registration not completing despite correct IAM role, endpoint, and security group configuration — under investigation (see Known Issues below)
- [ ] Attack simulation (Atomic Red Team / manual, mapped to MITRE ATT&CK)
- [ ] Automated response (Lambda + SNS)
- [ ] Full security report and threat model

## Known Issues

**SSM Session Manager registration failure (investigating):** the EC2 target instance has a correctly-configured IAM instance profile (`AmazonSSMManagedInstanceCore`), all three required VPC interface endpoints (`ssm`, `ssmmessages`, `ec2messages`) are `available`, and security group rules correctly allow HTTPS between the instance and the endpoints — all verified via AWS CLI. Despite this, and despite multiple full instance rebuilds and explicit `systemctl enable/start amazon-ssm-agent` via user_data, the instance is not appearing in `aws ssm describe-instance-information`. Console output capture has also been empty across multiple checks. Next steps: verify DNS resolution to the private endpoint from within the instance, check for a possible NACL or route table issue, and confirm the AMI's baked-in agent version is compatible with the endpoint region.

## Author

Sanika Mahamulkar — MSc Cybersecurity, University of Bristol
