# =============================================================================
# Hosted Zone Outputs
# =============================================================================

output "zone_ids" {
  description = "Map of zone key to zone ID for all created hosted zones."
  value       = { for k, v in local.all_zones : k => v.zone_id }
}

output "zone_arns" {
  description = "Map of zone key to zone ARN for all created hosted zones."
  value       = { for k, v in local.all_zones : k => v.arn }
}

output "zone_name_servers" {
  description = "Map of zone key to name servers for all created hosted zones."
  value       = { for k, v in local.all_zones : k => v.name_servers }
}

output "zone_primary_name_servers" {
  description = "Map of zone key to primary name server for all created hosted zones."
  value       = { for k, v in local.all_zones : k => v.primary_name_server }
}

output "zone_names" {
  description = "Map of zone key to zone name for all created hosted zones."
  value       = { for k, v in local.all_zones : k => v.name }
}

output "vpc_association_authorizations" {
  description = "All created Route53 VPC association authorizations (key = <zone_key>-<authorization_key>)."
  value       = aws_route53_vpc_association_authorization.this
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

output "delegation_set_reference_names" {
  description = "Map of delegation set key to reference name."
  value       = { for k, v in aws_route53_delegation_set.this : k => v.reference_name }
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

output "resolver_endpoint_ip_addresses" {
  description = "Map of resolver endpoint key to its IP address configuration."
  value       = { for k, v in aws_route53_resolver_endpoint.this : k => v.ip_address }
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

# =============================================================================
# Resolver Endpoint Security Group Outputs
# =============================================================================

output "resolver_endpoint_security_group_ids" {
  description = "Map of resolver endpoint key to the ID of the security group created by the module (create_security_group = true)."
  value       = { for k, v in aws_security_group.resolver : k => v.id }
}

output "resolver_endpoint_security_group_arns" {
  description = "Map of resolver endpoint key to the ARN of the security group created by the module."
  value       = { for k, v in aws_security_group.resolver : k => v.arn }
}

# =============================================================================
# DNSSEC Outputs
# =============================================================================

output "dnssec_kms_key_arn" {
  description = "ARN of the DNSSEC KMS key created by the module (null when not created)."
  value       = try(aws_kms_key.dnssec[0].arn, null)
}

output "dnssec_kms_key_id" {
  description = "ID of the DNSSEC KMS key created by the module (null when not created)."
  value       = try(aws_kms_key.dnssec[0].key_id, null)
}

output "dnssec_kms_key_policy" {
  description = "Policy of the DNSSEC KMS key created by the module (null when not created)."
  value       = try(aws_kms_key.dnssec[0].policy, null)
}

output "dnssec_key_signing_key_ids" {
  description = "Map of zone key to key-signing key ID (hosted_zone_id,name)."
  value       = { for k, v in aws_route53_key_signing_key.this : k => v.id }
}

output "dnssec_ds_records" {
  description = "Map of zone key to the DS record to publish in the parent zone / registrar."
  value       = { for k, v in aws_route53_key_signing_key.this : k => v.ds_record }
}

output "dnssec_digest_values" {
  description = "Map of zone key to the KSK digest value (SHA-256)."
  value       = { for k, v in aws_route53_key_signing_key.this : k => v.digest_value }
}

output "dnssec_dnskey_records" {
  description = "Map of zone key to the KSK DNSKEY record."
  value       = { for k, v in aws_route53_key_signing_key.this : k => v.dnskey_record }
}

output "dnssec_key_tags" {
  description = "Map of zone key to the KSK key tag."
  value       = { for k, v in aws_route53_key_signing_key.this : k => v.key_tag }
}

output "dnssec_public_keys" {
  description = "Map of zone key to the KSK public key (base64)."
  value       = { for k, v in aws_route53_key_signing_key.this : k => v.public_key }
}

# =============================================================================
# Resolver DNS Firewall Outputs
# =============================================================================

output "firewall_domain_list_ids" {
  description = "Map of domain list key to ID: shared lists (var.firewall_domain_lists) and inline lists (key = <group>-<rule>)."
  value = merge(
    { for k, v in aws_route53_resolver_firewall_domain_list.this : k => v.id },
    { for k, v in aws_route53_resolver_firewall_domain_list.rule : k => v.id }
  )
}

output "firewall_domain_list_arns" {
  description = "Map of domain list key to ARN: shared lists and inline lists (key = <group>-<rule>)."
  value = merge(
    { for k, v in aws_route53_resolver_firewall_domain_list.this : k => v.arn },
    { for k, v in aws_route53_resolver_firewall_domain_list.rule : k => v.arn }
  )
}

output "firewall_rule_group_ids" {
  description = "Map of rule group key to rule group ID."
  value       = { for k, v in aws_route53_resolver_firewall_rule_group.this : k => v.id }
}

output "firewall_rule_group_arns" {
  description = "Map of rule group key to rule group ARN."
  value       = { for k, v in aws_route53_resolver_firewall_rule_group.this : k => v.arn }
}

output "firewall_rule_group_share_status" {
  description = "Map of rule group key to share status (NOT_SHARED, SHARED_WITH_ME, SHARED_BY_ME)."
  value       = { for k, v in aws_route53_resolver_firewall_rule_group.this : k => v.share_status }
}

output "firewall_rules" {
  description = "All created DNS Firewall rules (key = <group>-<rule>)."
  value       = aws_route53_resolver_firewall_rule.this
}

output "firewall_rule_group_association_ids" {
  description = "Map of association key (<group>-<association>) to rule group association ID."
  value       = { for k, v in aws_route53_resolver_firewall_rule_group_association.this : k => v.id }
}

output "firewall_ram_resource_associations" {
  description = "All created RAM resource associations for rule groups (key = <group>-<share>)."
  value       = aws_ram_resource_association.firewall_rule_group
}
