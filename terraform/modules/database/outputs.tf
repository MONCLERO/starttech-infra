
output "redis_endpoint" {
  description = "Endpoint for Redis exported"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_port" {
  value = aws_elasticache_replication_group.redis.port
}

output "redis_security_group_id" {
  value = aws_security_group.redis.id
}
