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

# Avoid a warning for providing a variable that is not used.
variable "TFC_AWS_RUN_ROLE_ARN" {
  type    = string
  default = null
}

# Avoid a warning for providing a variable that is not used.
variable "TFC_AWS_PROVIDER_AUTH" {
  type    = bool
  default = false
}

# OpenID provider for GitHub Actions. This allows GitHub Actions to assume roles
# in our AWS account and it can be used by multiple roles.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  # Also known in AWS interfaces as "Audience"
  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name        = "github-actions"
    Description = "Allows GitHub Actions to assume roles in this account"
  }
}