
# ----- PROJECT CONFIGURATION ----- #

variable "project_name" {
  description = "Project identifier used for Redis resource naming and tagging."
  type        = string
}

# ----- NETWORK CONFIGURATION ----- #

variable "vpc_id" {
  description = "ID of the VPC hosting the Redis infrastructure."
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets used by the Redis subnet group."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least two private subnet IDs are required for the Redis subnet group."
  }
}

variable "eks_cluster_security_group_id" {
  description = "Security group ID associated with the EKS cluster and its managed worker nodes."
  type        = string
}
