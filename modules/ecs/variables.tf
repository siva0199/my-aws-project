variable "vpc_id" { type = string }
variable "public_subnet_id" { type = string }
variable "public_subnet_b_id" { type = string }
variable "private_app_subnet_id" { type = string }
variable "ecs_task_execution_role_arn" { type = string }
variable "ec2_instance_profile_name" { type = string }
variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for the ALB."
  type        = string
}
