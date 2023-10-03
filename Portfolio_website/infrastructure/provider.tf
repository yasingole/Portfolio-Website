# Terraform Block
terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0.0"
    }
  }

  backend "s3" {
  bucket = "yasingole.co.uk-terraform"
  key = "prod/terraform.tfstate"
  region = "eu-west-2"
  }
}

# Provider Block
provider "aws" {
  region  = "eu-west-2"
}

provider "aws" {
  alias  = "acm_provider"
  region = "us-east-1"
}

/*
The second AWS provider is specifically for the SSL certificate. These need to be created in us-east-1 
for Cloudfront to be able to use 
*/