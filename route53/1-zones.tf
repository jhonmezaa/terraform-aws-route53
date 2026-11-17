# =============================================================================
# Route53 Hosted Zones
# =============================================================================

locals {
  # Delegation sets only apply to public zones. delegation_set_id (external) takes
  # precedence over delegation_set_key (delegation set created in this module).
  zone_delegation_set_ids = {
    for k, v in var.zones : k => length(v.vpc) == 0 ? try(
      coalesce(
        v.delegation_set_id,
        try(aws_route53_delegation_set.this[v.delegation_set_key].id, null)
      ),
      null
    ) : null
  }
}

resource "aws_route53_zone" "this" {
  for_each = { for k, v in var.zones : k => v if var.create && !v.ignore_vpc }

  name              = each.value.domain_name
  comment           = each.value.comment
  force_destroy     = each.value.force_destroy
  delegation_set_id = local.zone_delegation_set_ids[each.key]

  dynamic "vpc" {
    for_each = each.value.vpc

    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.vpc_region
    }
  }

  tags = merge(
    local.common_tags,
    each.value.tags,
    {
      Name      = each.value.domain_name
      ManagedBy = "Terraform"
    }
  )

  lifecycle {
    precondition {
      condition     = each.value.delegation_set_key == null || contains(keys(var.delegation_sets), coalesce(each.value.delegation_set_key, "-"))
      error_message = "delegation_set_key de la zona \"${each.key}\" no existe en var.delegation_sets."
    }
  }
}

# Same as aws_route53_zone.this, but ignores changes to the VPC associations after
# creation. Use it (ignore_vpc = true) for private zones whose additional VPC
# associations are managed outside this module (e.g. aws_route53_zone_association
# in other accounts, authorized through vpc_association_authorizations).
resource "aws_route53_zone" "ignore_vpc" {
  for_each = { for k, v in var.zones : k => v if var.create && v.ignore_vpc }

  name              = each.value.domain_name
  comment           = each.value.comment
  force_destroy     = each.value.force_destroy
  delegation_set_id = local.zone_delegation_set_ids[each.key]

  dynamic "vpc" {
    for_each = each.value.vpc

    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.vpc_region
    }
  }

  tags = merge(
    local.common_tags,
    each.value.tags,
    {
      Name      = each.value.domain_name
      ManagedBy = "Terraform"
    }
  )

  lifecycle {
    ignore_changes = [vpc]

    precondition {
      condition     = each.value.delegation_set_key == null || contains(keys(var.delegation_sets), coalesce(each.value.delegation_set_key, "-"))
      error_message = "delegation_set_key de la zona \"${each.key}\" no existe en var.delegation_sets."
    }
  }
}

# =============================================================================
# VPC Association Authorizations (cross-account private zone associations)
# =============================================================================

locals {
  zone_vpc_association_authorizations = merge([
    for zone_key, zone in var.zones : {
      for auth_key, auth in zone.vpc_association_authorizations :
      "${zone_key}-${auth_key}" => merge(auth, { zone_key = zone_key })
    }
  ]...)
}

resource "aws_route53_vpc_association_authorization" "this" {
  for_each = { for k, v in local.zone_vpc_association_authorizations : k => v if var.create }

  zone_id    = local.zone_id_map[each.value.zone_key]
  vpc_id     = each.value.vpc_id
  vpc_region = each.value.vpc_region
}
