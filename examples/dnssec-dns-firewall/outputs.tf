output "zone_name_servers" {
  description = "Name servers of the public zone."
  value       = module.route53.zone_name_servers
}

output "dnssec_ds_records" {
  description = "DS records to publish at the registrar / parent zone."
  value       = module.route53.dnssec_ds_records
}

output "dnssec_kms_key_arn" {
  description = "ARN of the DNSSEC KMS key."
  value       = module.route53.dnssec_kms_key_arn
}

output "resolver_endpoint_ids" {
  description = "Resolver endpoint IDs."
  value       = module.route53.resolver_endpoint_ids
}

output "resolver_endpoint_security_group_ids" {
  description = "Security groups created for the resolver endpoints."
  value       = module.route53.resolver_endpoint_security_group_ids
}

output "firewall_rule_group_ids" {
  description = "DNS Firewall rule group IDs."
  value       = module.route53.firewall_rule_group_ids
}

output "firewall_rule_group_association_ids" {
  description = "DNS Firewall rule group association IDs."
  value       = module.route53.firewall_rule_group_association_ids
}
