output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.ecs.alb_dns_name
}

output "api_upload_url" {
  description = "The URL for the file upload API"
  value       = "${module.serverless.api_endpoint}/upload"
}
