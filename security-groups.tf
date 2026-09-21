resource "aws_security_group" "public_web" {
  name        = "security-lab-public-web-sg"
  description = "Security group for public-facing web resources"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security-lab-public-web-sg"
  }
}

resource "aws_security_group" "private_internal" {
  name        = "security-lab-private-internal-sg"
  description = "Security group for private subnet resources"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "All traffic from within the VPC only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security-lab-private-internal-sg"
  }
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

resource "aws_security_group" "ssh_restricted" {
  name        = "security-lab-ssh-restricted-sg"
  description = "SSH access restricted to a specific IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security-lab-ssh-restricted-sg"
  }
}
