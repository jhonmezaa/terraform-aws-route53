# =============================================================================
# Zone Outputs
# =============================================================================

output "zone_ids" {
  description = "Map of zone key to zone ID."
  value       = module.route53.zone_ids
}

output "zone_arns" {
  description = "Map of zone key to zone ARN."
  value       = module.route53.zone_arns
}

output "zone_name_servers" {
  description = "Map of zone key to name servers."
  value       = module.route53.zone_name_servers
}

output "zone_names" {
  description = "Map of zone key to zone name."
  value       = module.route53.zone_names
}

# =============================================================================
# Record Outputs
# =============================================================================

output "record_fqdns" {
  description = "Map of record key to FQDN."
  value       = module.route53.record_fqdns
}

output "record_names" {
  description = "Map of record key to record name."
  value       = module.route53.record_names
}

# =============================================================================
# Health Check Outputs
# =============================================================================

output "health_check_ids" {
  description = "Map of health check key to health check ID."
  value       = module.route53.health_check_ids
}

output "health_check_arns" {
  description = "Map of health check key to health check ARN."
  value       = module.route53.health_check_arns
}

# =============================================================================
# Delegation Set Outputs
# =============================================================================

output "delegation_set_ids" {
  description = "Map of delegation set key to delegation set ID."
  value       = module.route53.delegation_set_ids
}

output "delegation_set_name_servers" {
  description = "Map of delegation set key to name servers."
  value       = module.route53.delegation_set_name_servers
}
