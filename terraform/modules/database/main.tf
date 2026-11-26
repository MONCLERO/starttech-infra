
# ==================================================
# REDIS ELASTICACHE CONFIGURATION
# ==================================================

# ----- REDIS SUBNET GROUP ----- #

resource "aws_elasticache_subnet_group" "redis" {
  name        = "${var.project_name}-redis-subnet-group"
  description = "Private subnet group for StartTech Redis."

  subnet_ids = var.private_subnet_ids

  tags = {
    Name      = "${var.project_name}-redis-subnet-group"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

# ----- REDIS SECURITY GROUP ----- #

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Controls access to the StartTech Redis cache."
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow Redis traffic from the EKS cluster security group."
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.eks_cluster_security_group_id]
  }

  egress {
    description = "Allow outbound traffic."
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

# ----- REDIS REPLICATION GROUP ----- #

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project_name}-redis"
  description          = "Redis cache for the StartTech backend."

  engine         = "redis"
  engine_version = "7.1"
  node_type      = "cache.t3.micro"

  # Single-node Redis configuration.
  num_cache_clusters         = 1
  automatic_failover_enabled = false

  port               = 6379
  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  # Encryption at rest.
  at_rest_encryption_enabled = true

  tags = {
    Name      = "${var.project_name}-redis"
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}
