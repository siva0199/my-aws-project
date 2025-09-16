terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# A random string to make our S3 bucket name unique
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

module "networking" {
  source = "../../modules/networking"
}

module "iam" {
  source         = "../../modules/iam"
  s3_bucket_name = "my-unique-upload-bucket-${random_string.bucket_suffix.result}"
}

module "serverless" {
  source               = "../../modules/serverless"
  s3_bucket_name       = "my-unique-upload-bucket-${random_string.bucket_suffix.result}"
  lambda_exec_role_arn = module.iam.lambda_exec_role_arn
}

module "ecs" {
  source                      = "../../modules/ecs"
  vpc_id                      = module.networking.vpc_id
  public_subnet_id            = module.networking.public_subnet_id
  public_subnet_b_id          = module.networking.public_subnet_b_id
  private_app_subnet_id       = module.networking.private_app_subnet_id
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  ec2_instance_profile_name   = module.iam.ec2_instance_profile_name
}
