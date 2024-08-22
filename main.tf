terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.63.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Generate key pair
resource "tls_private_key" "sonar" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "sonar" {
  content  = tls_private_key.sonar.private_key_pem
  filename = "${path.module}/sonar.pem"
}

resource "aws_key_pair" "sonar" {
  key_name   = "sonar"
  public_key = tls_private_key.sonar.public_key_openssh
}

# Security group for SonarQube
resource "aws_security_group" "sonar" {
  name        = "sonar-new"
  description = "Security group for SonarQube"
  vpc_id      = "vpc-0bcc5af550894bac2"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Custom TCP for SonarQube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sonar"
  }
}

# EC2 instance for SonarQube
resource "aws_instance" "sonar" {
  ami             = "ami-0522ab6e1ddcc7055"
  instance_type   = "t2.medium"
  key_name        = aws_key_pair.sonar.key_name
  security_groups = [aws_security_group.sonar.name]

  user_data = templatefile("${path.module}/user_data.tpl", {
    DOCKER_COMPOSE_VERSION = "1.29.2"
  })

  tags = {
    Name = "sonarqube"
  }
}

