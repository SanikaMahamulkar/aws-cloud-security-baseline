data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "security_lab" {
  key_name   = "security-lab-key"
  public_key = file("~/.ssh/security-lab-key.pub")
}

resource "aws_instance" "target" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private[0].id
  key_name               = aws_key_pair.security_lab.key_name
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  ebs_optimized          = true
  monitoring              = true
  user_data              = <<-USERDATA
    #!/bin/bash
    dnf install -y https://s3.eu-west-2.amazonaws.com/amazon-ssm-eu-west-2/latest/linux_amd64/amazon-ssm-agent.rpm
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    USERDATA
  vpc_security_group_ids = [aws_security_group.private_internal.id]

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "security-lab-target"
  }
}

