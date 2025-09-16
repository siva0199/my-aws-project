output "acm_certificate_arn" {
  description = "The ARN of the imported self-signed ACM certificate."
  value       = aws_acm_certificate.this.arn
}
