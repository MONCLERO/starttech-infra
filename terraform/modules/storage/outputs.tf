
# ----- FRONTEND S3 OUTPUTS ----- #

output "frontend_bucket_name" {
  description = "Name of the private S3 bucket hosting the React frontend."
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_arn" {
  description = "ARN of the frontend S3 bucket, used by CloudFront access policies."
  value       = aws_s3_bucket.frontend.arn
}

output "frontend_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket, used as the CloudFront S3 origin."
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

# ----- BACKEND ECR OUTPUTS ----- #

output "backend_ecr_repository_url" {
  description = "URL of the ECR repository used to push and pull backend Docker images."
  value       = aws_ecr_repository.backend.repository_url
}

output "backend_ecr_repository_arn" {
  description = "ARN of the ECR repository, used for IAM permissions."
  value       = aws_ecr_repository.backend.arn
}
