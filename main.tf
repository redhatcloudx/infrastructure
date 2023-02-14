terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  cloud {
    organization = "major"
    workspaces {
      name = "infrastructure"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project     = "infrastructure"
      Environment = "dev"
      Owner       = "cloudx"
    }
  }
}

resource "aws_s3_bucket" "cloudx_json_bucket" {
  bucket = "cloudx-json-bucket"
}

resource "aws_s3_bucket_acl" "example_bucket_acl" {
  bucket = aws_s3_bucket.cloudx_json_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_website_configuration" "cloudx_testing" {
  bucket = aws_s3_bucket.cloudx_json_bucket.bucket

  index_document {
    suffix = "index.json"
  }
}