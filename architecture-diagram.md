# Architecture Diagram

```mermaid
flowchart TB
    subgraph AWS["AWS Account 767398012336 — eu-west-2"]
        subgraph VPC["VPC (10.0.0.0/16)"]
            subgraph PublicSubnets["Public Subnets (2 AZs)"]
                IGW[Internet Gateway]
                PublicSG[Security Group:<br/>public-web-sg<br/>80/443 ingress]
            end

            subgraph PrivateSubnets["Private Subnets (2 AZs)"]
                EC2[EC2 Target Instance<br/>t3.micro, encrypted,<br/>IMDSv2, EBS-optimized]
                PrivateSG[Security Group:<br/>private-internal-sg<br/>VPC-only ingress]
                Endpoints[VPC Interface Endpoints:<br/>ssm, ssmmessages,<br/>ec2messages]
                EndpointSG[Security Group:<br/>vpc-endpoints-sg<br/>HTTPS from VPC]
            end

            SSHRestricted[Security Group:<br/>ssh-restricted-sg<br/>SSH from admin IP only]
        end

        subgraph Logging["Logging & Compliance"]
            CloudTrail[CloudTrail<br/>multi-region, validated]
            Config[AWS Config<br/>5 compliance rules]
            S3Logs[(S3: CloudTrail logs<br/>KMS-encrypted)]
            S3Config[(S3: Config logs<br/>KMS-encrypted)]
        end

        subgraph Detection["Detection & Response"]
            GuardDuty[GuardDuty<br/>S3 + malware protection]
            EventBridge[EventBridge Rule]
            Lambda[Lambda:<br/>guardduty-response]
            SNS[SNS Topic:<br/>security-alerts]
            Email[Email Subscriber]
        end

        subgraph IAM["Identity & Access"]
            AdminUser[IAM User: sanika-admin<br/>scoped least-privilege policy<br/>NO AdministratorAccess]
            SSMRole[IAM Role: EC2 → SSM]
            ConfigRole[IAM Role: Config service]
            LambdaRole[IAM Role: Lambda → SNS]
        end

        KMS[(Customer-Managed KMS Key<br/>auto-rotation enabled)]
    end

    IGW --> PublicSG
    EC2 --> PrivateSG
    EC2 -.IAM role.-> SSMRole
    SSMRole -.-> Endpoints
    Endpoints --> EndpointSG

    EC2 --> CloudTrail
    CloudTrail --> S3Logs
    Config --> S3Config
    Config -.IAM role.-> ConfigRole

    GuardDuty --> EventBridge
    EventBridge --> Lambda
    Lambda -.IAM role.-> LambdaRole
    Lambda --> SNS
    SNS --> Email

    KMS -.encrypts.-> S3Logs
    KMS -.encrypts.-> S3Config
    KMS -.encrypts.-> EC2

    AdminUser -.manages via Terraform.-> VPC
    AdminUser -.manages via Terraform.-> Logging
    AdminUser -.manages via Terraform.-> Detection
```

## Component Summary

| Layer | Components |
|---|---|
| **Network** | VPC, 2 public + 2 private subnets across 2 AZs, IGW, route tables, 3 security groups, 3 VPC interface endpoints |
| **Compute** | EC2 target instance (private subnet, encrypted, IMDSv2 enforced, EBS-optimized, detailed monitoring) |
| **Logging** | Multi-region CloudTrail, AWS Config with 5 compliance rules, both writing to KMS-encrypted S3 |
| **Detection** | GuardDuty (S3 + malware protection), 400 sample findings mapped to 8 MITRE ATT&CK tactics |
| **Response** | EventBridge → Lambda → SNS, validated end-to-end via direct invocation |
| **Encryption** | Customer-managed KMS key with automatic rotation, applied to all S3 buckets, DynamoDB, and EBS |
| **IAM** | Least-privilege policy (no AdministratorAccess), scoped IAM roles per service (SSM, Config, Lambda) |
