# Reuse existing OIDC provider if provided; otherwise create one
data "aws_iam_openid_connect_provider" "existing" {
  count = var.github_oidc_provider_arn != null ? 1 : 0
  arn   = var.github_oidc_provider_arn
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.github_oidc_provider_arn == null ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

locals {
  github_oidc_provider_arn = coalesce(
    var.github_oidc_provider_arn,
    try(one(data.aws_iam_openid_connect_provider.existing[*].arn), null),
    try(one(aws_iam_openid_connect_provider.github[*].arn), null)
  )
}

# Trust policy for GitHub Actions OIDC
data "aws_iam_policy_document" "github_oidc_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Allow all branches for this repo
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.github_org}/${local.github_repo}:ref:${var.github_ref}"]
    }
  }
}

resource "aws_iam_role" "github_oidc_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json
  description        = "OIDC role for GitHub Actions (${var.github_repo_full})"
}

# Attach broad permissions for simplicity (tighten later!)
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Allow access to S3 backend (bucket + prefix)
data "aws_iam_policy_document" "tf_backend" {
  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::tf-state-dt-123456789"]
  }
  statement {
    sid       = "RWStateObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::tf-state-dt-123456789/staging/*"]
  }
  # (uncomment if you use DynamoDB locks)
  # statement {
  #   sid     = "StateLocksDDB"
  #   effect  = "Allow"
  #   actions = ["dynamodb:DescribeTable","dynamodb:GetItem","dynamodb:PutItem","dynamodb:UpdateItem","dynamodb:DeleteItem"]
  #   resources = ["arn:aws:dynamodb:eu-central-1:<ACCOUNT_ID>:table/tf-state-locks"]
  # }
}

resource "aws_iam_policy" "tf_backend" {
  name   = "${var.role_name}-tf-backend"
  policy = data.aws_iam_policy_document.tf_backend.json
}

resource "aws_iam_role_policy_attachment" "attach_backend" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = aws_iam_policy.tf_backend.arn
}

output "github_oidc_role_arn" {
  value       = aws_iam_role.github_oidc_role.arn
  description = "Paste into GitHub Secrets as AWS_OIDC_ROLE_ARN"
}
