# =============================================================================
# Hosted Zone Outputs
# =============================================================================

output "zone_ids" {
  description = "Map of zone key to zone ID for all created hosted zones."
  value       = { for k, v in aws_route53_zone.this : k => v.zone_id }
}

output "zone_arns" {
  description = "Map of zone key to zone ARN for all created hosted zones."
  value       = { for k, v in aws_route53_zone.this : k => v.arn }
}

output "zone_name_servers" {
  description = "Map of zone key to name servers for all created hosted zones."
  value       = { for k, v in aws_route53_zone.this : k => v.name_servers }
}

output "zone_primary_name_servers" {
  description = "Map of zone key to primary name server for all created hosted zones."
  value       = { for k, v in aws_route53_zone.this : k => v.primary_name_server }
}

output "zone_names" {
  description = "Map of zone key to zone name for all created hosted zones."
  value       = { for k, v in aws_route53_zone.this : k => v.name }
}

# =============================================================================
# Record Outputs
# =============================================================================

output "record_names" {
  description = "Map of record key to record name for all created records."
  value       = { for k, v in aws_route53_record.this : k => v.name }
}

output "record_fqdns" {
  description = "Map of record key to FQDN for all created records."
  value       = { for k, v in aws_route53_record.this : k => v.fqdn }
}

output "records" {
  description = "All created Route53 records with their full attributes."
  value       = aws_route53_record.this
}

# =============================================================================
# Health Check Outputs
# =============================================================================

output "health_check_ids" {
  description = "Map of health check key to health check ID for all created health checks."
  value       = { for k, v in aws_route53_health_check.this : k => v.id }
}

output "health_check_arns" {
  description = "Map of health check key to health check ARN for all created health checks."
  value       = { for k, v in aws_route53_health_check.this : k => v.arn }
}

output "health_checks" {
  description = "All created Route53 health checks with their full attributes."
  value       = aws_route53_health_check.this
}

# =============================================================================
# Delegation Set Outputs
# =============================================================================

output "delegation_set_ids" {
  description = "Map of delegation set key to delegation set ID."
  value       = { for k, v in aws_route53_delegation_set.this : k => v.id }
}

output "delegation_set_name_servers" {
  description = "Map of delegation set key to name servers."
  value       = { for k, v in aws_route53_delegation_set.this : k => v.name_servers }
}

# =============================================================================
# Resolver Endpoint Outputs
# =============================================================================

output "resolver_endpoint_ids" {
  description = "Map of resolver endpoint key to resolver endpoint ID."
  value       = { for k, v in aws_route53_resolver_endpoint.this : k => v.id }
}

output "resolver_endpoint_arns" {
  description = "Map of resolver endpoint key to resolver endpoint ARN."
  value       = { for k, v in aws_route53_resolver_endpoint.this : k => v.arn }
}

output "resolver_endpoint_host_vpc_ids" {
  description = "Map of resolver endpoint key to host VPC ID."
  value       = { for k, v in aws_route53_resolver_endpoint.this : k => v.host_vpc_id }
}

output "resolver_endpoints" {
  description = "All created Route53 Resolver endpoints with their full attributes."
  value       = aws_route53_resolver_endpoint.this
}

# =============================================================================
# Resolver Rule Outputs
# =============================================================================

output "resolver_rule_ids" {
  description = "Map of resolver rule key to resolver rule ID."
  value       = { for k, v in aws_route53_resolver_rule.this : k => v.id }
}

output "resolver_rule_arns" {
  description = "Map of resolver rule key to resolver rule ARN."
  value       = { for k, v in aws_route53_resolver_rule.this : k => v.arn }
}

output "resolver_rules" {
  description = "All created Route53 Resolver rules with their full attributes."
  value       = aws_route53_resolver_rule.this
}

output "resolver_rule_associations" {
  description = "All created Route53 Resolver rule associations."
  value       = aws_route53_resolver_rule_association.this
}
