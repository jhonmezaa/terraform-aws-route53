output "zone_ids" {
  description = "Map of zone key to zone ID."
  value       = module.route53.zone_ids
}

output "zone_name_servers" {
  description = "Map of zone key to name servers."
  value       = module.route53.zone_name_servers
}

output "record_fqdns" {
  description = "Map of record key to FQDN."
  value       = module.route53.record_fqdns
}
