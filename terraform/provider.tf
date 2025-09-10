terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket = "tf-state-dt-123456789"
    key    = "staging/terraform.tfstate" # path within the bucket (folder/file)
    region = "eu-central-1"
  }
}

provider "aws" {
  region = var.aws_region
}
