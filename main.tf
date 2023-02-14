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

resource "aws_s3_bucket" "cloudx_testing" {
  bucket = "cloudx-testing"
}
