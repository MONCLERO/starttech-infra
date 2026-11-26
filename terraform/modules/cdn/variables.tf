
# ----- PROJECT CONFIGURATION ----- #

variable "project_name" {
  description = "Project identifier used for CloudFront resource naming and tagging."
  type        = string
}

# ----- FRONTEND S3 CONFIGURATION ----- #

variable "frontend_bucket_id" {
  description = "ID of the private S3 bucket hosting the React frontend."
  type        = string
}

variable "frontend_bucket_arn" {
  description = "ARN of the frontend S3 bucket used in the CloudFront access policy."
  type        = string
}

variable "frontend_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket configured as the CloudFront origin."
  type        = string
}

# ----- BACKEND ALB CONFIGURATION ----- #

variable "backend_origin_domain_name" {
  description = "DNS hostname of the internet-facing Application Load Balancer serving the backend."
  type        = string

  validation {
    condition     = length(trimspace(var.backend_origin_domain_name)) > 0
    error_message = "A valid backend ALB DNS hostname must be supplied when CloudFront is enabled."
  }
}
