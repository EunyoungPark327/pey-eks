terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.24.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}
module "vpc" {
  source       = "./modules/vpc"
  vpc_name     = "pey-vpc-dev"
  vpc_cidr     = "10.21.0.0/16"
  cluster_name = "pey"
}
module "eks" {
  source          = "./modules/eks"
  cluster_name    = "pey"
  cluster_version = "1.31"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}
