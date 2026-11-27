
variable "project_name" {
  description = "Name of the project used for resource naming and tagging."
  type        = string
}

variable "cluster_name" {
  description = "Name of the Amazon EKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to run on the Amazon EKS cluster."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where the EKS cluster and managed worker nodes will be deployed."
  type        = list(string)
}

variable "node_instance_types" {
  description = "EC2 instance types used by the EKS managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes in the EKS managed node group."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes that the EKS managed node group can maintain."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes that the EKS managed node group can scale to."
  type        = number
  default     = 3
}

variable "github_actions_user_arn" {
  description = "ARN of the IAM user used by GitHub Actions, which receives access to manage resources inside the EKS cluster."
  type        = string
}
