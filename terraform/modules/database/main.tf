
# ----- REDIS CONFIG ----- #
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project_name}-redis"
  description          = "Redis cache for the starttech backend"

  engine         = "redis"
  engine_version = "7.1"
  node_type      = "cache.t3.micro"

  num_cache_clusters         = 1
  automatic_failover_enabled = false

  port               = 6379
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true

  tags = {
    Name      = "${var.project_name}-redis"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name        = "${var.project_name}-redis-subnet-group"
  description = "Private subnets for Redis"
  subnet_ids  = var.private_subnet_ids
}

# ----- REDIS SECURITY GROUP ----- #

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Allow Redis access from the EKS cluster security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis access from EKS"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.eks_cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project_name}-redis-sg"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}
