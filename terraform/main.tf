
# ----- TERRAFORM INIT ----- #

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.80, < 7.0"
    }
  }

  backend "s3" {}
}


provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}

# ----- MODULES ----- #

module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}


module "eks" {
  source = "./modules/eks"

  project_name       = var.project_name
  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  private_subnet_ids = module.networking.private_subnet_ids

  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
}


module "storage" {
  source = "./modules/storage"

  project_name           = var.project_name
  frontend_bucket_prefix = var.frontend_bucket_prefix
  ecr_repository_name    = var.ecr_repository_name
}


module "database" {
  source = "./modules/database"

  project_name                  = var.project_name
  vpc_id                        = module.networking.vpc_id
  private_subnet_ids            = module.networking.private_subnet_ids
  eks_cluster_security_group_id = module.eks.cluster_security_group_id
}


module "cdn" {
  count  = var.enable_cdn ? 1 : 0
  source = "./modules/cdn"

  project_name                         = var.project_name
  frontend_bucket_id                   = module.storage.frontend_bucket_name
  frontend_bucket_arn                  = module.storage.frontend_bucket_arn
  frontend_bucket_regional_domain_name = module.storage.frontend_bucket_regional_domain_name
  backend_origin_domain_name           = var.backend_origin_domain_name
}
