terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.47"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4.1"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

