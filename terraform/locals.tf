locals {
  name_prefix = "${var.app_name}-${var.environment}"
  github_org  = split("/", var.github_repo_full)[0]
  github_repo = split("/", var.github_repo_full)[1]

  # Amazon Linux 2 user_data: install Docker, login to ECR, run container on :80
  user_data_al2 = <<-EOF
  #!/bin/bash
  sudo -i
  set -euo pipefail
  yum update -y
  amazon-linux-extras enable docker
  yum install -y docker jq
  systemctl enable docker
  systemctl start docker

  if ! command -v aws >/dev/null 2>&1; then
    curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -q /tmp/awscliv2.zip -d /tmp && /tmp/aws/install
  fi

  REGION=${var.aws_region}
  ACCOUNT_ID=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .accountId)
  aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
  IMAGE_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${var.app_name}:${var.image_tag}

  docker pull $IMAGE_URI || true
  docker stop ${var.app_name} || true
  docker rm ${var.app_name} || true
  docker run -d --name ${var.app_name} -p 80:8080 --restart unless-stopped -e MESSAGE="Hello from ${var.environment} on $(hostname)" $IMAGE_URI

  systemctl enable amazon-ssm-agent || true
  systemctl start amazon-ssm-agent || true
  EOF
}
