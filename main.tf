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