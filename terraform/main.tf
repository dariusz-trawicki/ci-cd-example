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
