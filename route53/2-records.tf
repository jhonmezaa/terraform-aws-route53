# =============================================================================
# Route53 DNS Records
# =============================================================================

resource "aws_route53_record" "this" {
  for_each = { for k, v in local.records_with_zone : k => v if var.create }

  zone_id = each.value.resolved_zone_id

  name = coalesce(
    each.value.full_name,
    each.value.name,
    each.key
  )

  type            = each.value.type
  ttl             = each.value.alias != null ? null : each.value.ttl
  records         = each.value.records
  set_identifier  = each.value.set_identifier
  health_check_id = each.value.resolved_health_check_id
  allow_overwrite = each.value.allow_overwrite

  multivalue_answer_routing_policy = each.value.multivalue_answer

  # Alias record
  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []

    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  # Weighted routing policy
  dynamic "weighted_routing_policy" {
    for_each = each.value.weighted_routing_policy != null ? [each.value.weighted_routing_policy] : []

    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  # Latency routing policy
  dynamic "latency_routing_policy" {
    for_each = each.value.latency_routing_policy != null ? [each.value.latency_routing_policy] : []

    content {
      region = latency_routing_policy.value.region
    }
  }

  # Failover routing policy
  dynamic "failover_routing_policy" {
    for_each = each.value.failover_routing_policy != null ? [each.value.failover_routing_policy] : []

    content {
      type = failover_routing_policy.value.type
    }
  }

  # Geolocation routing policy
  dynamic "geolocation_routing_policy" {
    for_each = each.value.geolocation_routing_policy != null ? [each.value.geolocation_routing_policy] : []

    content {
      continent   = geolocation_routing_policy.value.continent
      country     = geolocation_routing_policy.value.country
      subdivision = geolocation_routing_policy.value.subdivision
    }
  }

  # Geoproximity routing policy
  dynamic "geoproximity_routing_policy" {
    for_each = each.value.geoproximity_routing_policy != null ? [each.value.geoproximity_routing_policy] : []

    content {
      aws_region       = geoproximity_routing_policy.value.aws_region
      bias             = geoproximity_routing_policy.value.bias
      local_zone_group = geoproximity_routing_policy.value.local_zone_group

      dynamic "coordinates" {
        for_each = geoproximity_routing_policy.value.coordinates != null ? geoproximity_routing_policy.value.coordinates : []

        content {
          latitude  = coordinates.value.latitude
          longitude = coordinates.value.longitude
        }
      }
    }
  }

  # CIDR routing policy
  dynamic "cidr_routing_policy" {
    for_each = each.value.cidr_routing_policy != null ? [each.value.cidr_routing_policy] : []

    content {
      collection_id = cidr_routing_policy.value.collection_id
      location_name = cidr_routing_policy.value.location_name
    }
  }
}
