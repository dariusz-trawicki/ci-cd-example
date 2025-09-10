# ----- Common -----
variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "app_name" {
  type    = string
  default = "myapp"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "ssh_key_name" {
  type    = string
  default = "test-ec2-key" # name Key Pair in AWS
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/test-ec2-key.pub" # only for local apply
}

# Empty disables SSH entirely (we use SSM instead).
variable "ssh_cidr" {
  type    = string
  default = "" # SSH disabled (must be for Github action)
  # default = "109.241.40.117/32" # allow SSH only from my_IP
}

# Image tag that the pipeline will push to ECR
variable "image_tag" {
  type    = string
  default = "staging-latest"
}

# ----- GitHub OIDC / IAM -----
# Full repo name in ORG/REPO format
variable "github_repo_full" {
  type    = string
  default = "dariusz-trawicki/ci-cd-example"
}

# Allow all branches; change to a specific ref e.g. "refs/heads/develop" if you want to restrict
variable "github_ref" {
  type    = string
  default = "refs/heads/*"
}

# Role name to be assumed by GitHub Actions
variable "role_name" {
  type    = string
  default = "github-ci-cd-role"
}

# If an OIDC provider for GitHub already exists in the account, provide its ARN here to reuse it.
# If null, Terraform will create a new OIDC provider.
variable "github_oidc_provider_arn" {
  type        = string
  default     = null
  description = "Existing GitHub OIDC provider ARN (optional). If null, create a new provider."
}

# Managed policies attached to the role (adjust to least privilege for your use case)
variable "policy_arns" {
  type = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

variable "tf_state_bucket" {
  type        = string
  description = "S3 bucket for Terraform state"
  default     = "tf-state-dt-123456789"
}

variable "tf_state_key_prefix" {
  type        = string
  description = "Key prefix (folder) inside the bucket for TF state"
  default     = "staging"
}
