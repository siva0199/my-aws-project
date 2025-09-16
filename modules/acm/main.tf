# This provider is needed to generate the certificate locally
terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Generate a private key
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Generate a self-signed certificate using the private key
resource "tls_self_signed_cert" "this" {
  private_key_pem = tls_private_key.this.private_key_pem

  subject {
    common_name  = "project-demo.internal"
    organization = "Demo Corp"
  }

  validity_period_hours = 8760 # Valid for 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Import the generated certificate into AWS Certificate Manager
resource "aws_acm_certificate" "this" {
  private_key      = tls_private_key.this.private_key_pem
  
  # --- THIS IS THE CORRECTED LINE ---
  certificate_body = tls_self_signed_cert.this.cert_pem 

  tags = {
    Name = "self-signed-cert-for-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}
