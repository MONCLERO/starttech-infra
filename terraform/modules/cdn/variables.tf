
variable "project_name" {
  type = string
}

variable "frontend_bucket_id" {
  description = "S3 bucket ID for the frontend"
  type        = string
}

variable "frontend_bucket_arn" {
  description = "S3 bucket ARN for the frontend"
  type        = string
}

variable "frontend_bucket_regional_domain_name" {
  description = "Regional S3 bucket domain name"
  type        = string
}

variable "backend_origin_domain_name" {
  description = "DNS hostname of the backend Application Load Balancer"
  type        = string
}
