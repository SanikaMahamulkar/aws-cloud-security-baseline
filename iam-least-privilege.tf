data "aws_iam_policy_document" "terraform_scoped" {
  statement {
    sid    = "CoreInfrastructure"
    effect = "Allow"
    actions = [
      "ec2:*",
      "s3:*",
      "dynamodb:*",
      "cloudtrail:*",
      "guardduty:*",
      "config:*",
      "kms:*",
      "lambda:*",
      "sns:*",
      "events:*",
      "logs:*",
      "ssm:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IAMManagement"
    effect = "Allow"
    actions = [
      "iam:GetUser",
      "iam:GetRole",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicies",
      "iam:ListAttachedUserPolicies",
      "iam:ListAttachedRolePolicies",
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:AttachUserPolicy",
      "iam:DetachUserPolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:PassRole",
      "iam:TagRole",
      "iam:TagPolicy",
      "iam:CreateServiceLinkedRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:GetInstanceProfile",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IdentityAndAccountRead"
    effect = "Allow"
    actions = [
      "sts:GetCallerIdentity",
      "organizations:DescribeOrganization",
      "access-analyzer:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "terraform_scoped" {
  name        = "security-lab-terraform-scoped-policy"
  description = "Least-privilege policy for this project, scoped from Access Advisor evidence"
  policy      = data.aws_iam_policy_document.terraform_scoped.json
}
