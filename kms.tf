resource "aws_kms_key" "main" {
  description             = "Customer-managed key for security lab encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "security-lab-kms-key"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/security-lab-key"
  target_key_id = aws_kms_key.main.key_id
}
