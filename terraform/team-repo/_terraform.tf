// Configuration for Terraform itself.

terraform {
  required_version = "~> 0.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 1.2.0"
    }
    github = {
      source  = "hashicorp/github"
      version = "~> 2.9.2"
    }
  }

  backend "s3" {
    bucket         = "rust-terraform"
    key            = "simpleinfra/team-repo.tfstate"
    region         = "us-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  profile = "default"
  region  = "us-west-1"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
