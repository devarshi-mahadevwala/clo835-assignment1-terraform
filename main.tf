provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" { default = true }

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Generate an SSH keypair locally (PEM + public key)
resource "tls_private_key" "deployer" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Upload public key to AWS as a key pair
resource "aws_key_pair" "deployer" {
  key_name   = "clo835-deployer-key"
  public_key = tls_private_key.deployer.public_key_openssh
}

# Save private key to local Cloud9 filesystem (DO NOT commit this file to git)
resource "local_file" "private_key_pem" {
  filename = "${path.cwd}/clo835_deployer.pem"
  content  = tls_private_key.deployer.private_key_pem
  file_permission = "0400"
}

# ECR repositories
resource "aws_ecr_repository" "webapp" {
  name = "clo835-webapp"
}
resource "aws_ecr_repository" "mysql" {
  name = "clo835-mysql"
}

# Security group allowing SSH + 8081..8083
resource "aws_security_group" "ec2_sg" {
  name   = "clo835-ec2-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8081
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 IAM role for ECR pull
# resource "aws_iam_role" "ec2_role" {
#   name = "clo835-ec2-ecr-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "attach_ecr" {
#   role       = aws_iam_role.ec2_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }

# resource "aws_iam_instance_profile" "ec2_profile" {
#   name = "clo835-ec2-profile"
#   role = aws_iam_role.ec2_role.name
# }

# Find Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 instance (uses the created key pair)
resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = aws_key_pair.deployer.key_name
  # iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user_data.sh")
  tags = { Name = "clo835-ec2" }
}
