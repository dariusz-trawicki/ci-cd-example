provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "tf_state" {
  bucket        = "tf-state-dt-123456789"
  force_destroy = true # for test only

  tags = {
    Name = "Terraform State Bucket"
  }
}