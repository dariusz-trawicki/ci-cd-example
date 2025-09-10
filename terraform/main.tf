# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name_prefix}-vpc"
  cidr = "10.30.0.0/16"

  azs            = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets = ["10.30.10.0/24", "10.30.11.0/24"]

  enable_nat_gateway            = false
  manage_default_security_group = false
}

# ECR
resource "aws_ecr_repository" "app" {
  name                 = var.app_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
}

# SG (HTTP + optional SSH)
resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-sg"
  description = "Allow HTTP (+optional SSH)"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.ssh_cidr == "" ? [] : [1]
    content {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.ssh_cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-sg"
    Environment = var.environment
    App         = var.app_name
  }
}

# IAM for EC2 (pull from ECR + SSM)
resource "aws_iam_role" "ec2_role" {
  name = "${local.name_prefix}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_ro" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# AL2 AMI
data "aws_ami" "al2" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2
resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = var.ssh_cidr == "" ? null : one(aws_key_pair.this[*].key_name)
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  user_data                   = local.user_data_al2
  associate_public_ip_address = true

  tags = {
    Name        = "${local.name_prefix}-ec2"
    Environment = var.environment
    App         = var.app_name
  }
}
