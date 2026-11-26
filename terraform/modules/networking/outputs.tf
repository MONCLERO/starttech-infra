
# ----- VPC OUTPUTS ----- #

output "vpc_id" {
  description = "ID of the StartTech VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "IPv4 CIDR block of the StartTech VPC."
  value       = aws_vpc.main.cidr_block
}

# ----- AVAILABILITY ZONE OUTPUTS ----- #

output "availability_zones" {
  description = "Availability Zones used by the networking infrastructure."
  value       = local.availability_zones
}

# ----- PUBLIC SUBNET OUTPUTS ----- #

output "public_subnet_ids" {
  description = "IDs of the two public subnets."
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets."
  value       = aws_subnet.public[*].cidr_block
}

# ----- PRIVATE SUBNET OUTPUTS ----- #

output "private_subnet_ids" {
  description = "IDs of the two private subnets."
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets."
  value       = aws_subnet.private[*].cidr_block
}

# ----- NAT GATEWAY OUTPUTS ----- #

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways."
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "Public Elastic IP addresses assigned to the NAT Gateways."
  value       = aws_eip.nat[*].public_ip
}

# ----- INTERNET GATEWAY OUTPUT ----- #

output "internet_gateway_id" {
  description = "ID of the Internet Gateway attached to the VPC."
  value       = aws_internet_gateway.main.id
}
