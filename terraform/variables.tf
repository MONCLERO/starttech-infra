
variable "aws_region" {
  description = "AWS deployment region"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project identifier"
  type        = string
  default     = "starttech"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "starttech-cluster"
}

variable "cluster_version" {
  type    = string
  default = "1.35"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "vpc_cidr" {
  description = "VPC CIDR range"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_cdn" {
  description = "Whether to deploy the CloudFront distribution"
  type        = bool
  default     = false
}

variable "backend_origin_domain_name" {
  description = "DNS hostname of the Kubernetes Ingress ALB"
  type        = string
  default     = ""
}

variable "frontend_bucket_prefix" {
  type    = string
  default = "starttech-frontend-bucket"
}

variable "ecr_repository_name" {
  type    = string
  default = "starttech-backend-api"
}