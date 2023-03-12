terraform {
  required_version = ">= 1.3.9"
  required_providers {
    aws = {
      version = ">= 4.56.0"
      source  = "hashicorp/aws"
    }
    archive = {
      version = ">=2.3.0"
      source  = "hashicorp/archive"
    }
  }
  backend "s3" {
    bucket  = "brandslice-terraform-statefiles"
    region  = "us-east-1"
    profile = "brandslice"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
  default_tags {
    tags = {
      ManagedBy = "Terraform"
      StateFile = "s3://brandslice-terraform-statefiles/locally/datasync/terraform.tfstate"
    }
  }
}

provider "archive" {}

data "aws_caller_identity" "current" {}

data "aws_s3_bucket" "target" {
  bucket = "lynkemprod"
}

data "aws_vpc" "main" {
  cidr_block = "172.31.0.0/16"
}

data "aws_subnet" "use1a" {
  availability_zone = "us-east-1a"
  vpc_id            = data.aws_vpc.main.id
}

locals {
  target_path = "/Inventory_Data_Uploads/Locally_data/stock_inventory"
}
