
variable "project_name" {
  description = "Project identifier used for resource tagging."
  type = string
}

variable "frontend_bucket_prefix" {
  description = "Prefix for the globally unique frontend bucket name"
  type        = string
  default     = "starttech-frontend-bucket"
}

variable "ecr_repository_name" {
  description = "ECR repository for the backend application"
  type        = string
  default     = "starttech-backend-api"
}
