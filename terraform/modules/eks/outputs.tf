
output "cluster_name" {
  description = "EKS cluster identification"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Cluster CA certificate"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "node_group_name" {
  description = "Managed node group identification"
  value       = aws_eks_node_group.main.node_group_name
}

output "node_role_arn" {
  description = "Worker IAM role"
  value       = aws_iam_role.nodes.arn
}

output "cluster_security_group_id" {
  description = "Cluster security group"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "load_balancer_controller_role_arn" {
  description = "IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.load_balancer_controller.arn
}