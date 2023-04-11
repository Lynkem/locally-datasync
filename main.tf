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
  sync_configs = {
    inventory = {
      source_bucket        = "brandslice-stock"
      source_path          = "/brandslice-stock/"
      source_hostname      = "storage.googleapis.com"
      target_bucket_arn    = data.aws_s3_bucket.target.arn
      target_path          = "/Inventory_Data_Uploads/Locally_data/stock_inventory/"
      sync_schedule        = "cron(15 8 * * ? *)"
      agent_start_schedule = "cron(0 4 * * ? *)"
      excludes             = [{ filter_type = "SIMPLE_PATTERN", value = "/master-000000000000.csv" }]
    }
    catalog = {
      source_bucket        = "all-product-catalogs"
      source_path          = "/all-product-catalogs/"
      source_hostname      = "storage.googleapis.com"
      target_bucket_arn    = data.aws_s3_bucket.target.arn
      target_path          = "/Inventory_Data_Uploads/Locally_data/Product_Catalogs/"
      sync_schedule        = "cron(0 2 ? * MON *)"
      agent_start_schedule = "cron(45 21 ? * SUN *)"
      excludes             = []
    }
    roster = {
      source_bucket        = "brandslice-stores"
      source_path          = "/brandslice-stores/"
      source_hostname      = "storage.googleapis.com"
      target_bucket_arn    = data.aws_s3_bucket.target.arn
      target_path          = "/Inventory_Data_Uploads/Locally_data/Roster_file/"
      sync_schedule        = "cron(45 4 * * ? *)"
      agent_start_schedule = "cron(30 0 * * ? *)"
      excludes             = []
    }
  }
  title_keys       = { for k in keys(local.sync_configs) : k => title(k) }
  locally_iterator = toset(keys(local.sync_configs))
}
