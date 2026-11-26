
# ----- REDIS OUTPUTS ----- #

output "redis_endpoint" {
  description = "Primary endpoint address of the StartTech Redis replication group."
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_port" {
  description = "Port number used by the Redis cache."
  value       = aws_elasticache_replication_group.redis.port
}

output "redis_security_group_id" {
  description = "Security group ID controlling access to the Redis cache."
  value       = aws_security_group.redis.id
}
