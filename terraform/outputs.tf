
# ----- NETWORKING OUTPUTS ----- #

output "vpc_id" {
  description = "ID of the StartTech VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways"
  value       = module.networking.nat_gateway_ids
}


# ----- EKS OUTPUTS ----- #

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_node_group_name" {
  description = "Name of the EKS managed node group"
  value       = module.eks.node_group_name
}

output "eks_cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for EKS workload identity"
  value       = module.eks.cluster_oidc_issuer_url
}

output "load_balancer_controller_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller"
  value       = module.eks.load_balancer_controller_role_arn
}


# ----- STORAGE OUTPUTS ----- #

output "frontend_bucket_name" {
  description = "Name of the frontend S3 bucket"
  value       = module.storage.frontend_bucket_name
}

output "backend_ecr_repository_url" {
  description = "URL of the backend ECR repository"
  value       = module.storage.backend_ecr_repository_url
}


# ----- DATABASE OUTPUTS ----- #

output "redis_endpoint" {
  description = "Endpoint address of the Redis cluster"
  value       = module.database.redis_endpoint
}

output "redis_port" {
  description = "Port number of the Redis cluster"
  value       = module.database.redis_port
}


# ----- CLOUDFRONT OUTPUTS ----- #

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = try(module.cdn[0].cloudfront_distribution_id, null)
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = try(module.cdn[0].cloudfront_domain_name, null)
}
