
# ----- CLOUDFRONT OUTPUTS ----- #

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution used for cache invalidation."
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain_name" {
  description = "Public DNS domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.main.arn
}
