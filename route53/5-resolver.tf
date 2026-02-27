# =============================================================================
# Route53 Resolver Endpoints
# =============================================================================

resource "aws_route53_resolver_endpoint" "this" {
  for_each = { for k, v in var.resolver_endpoints : k => v if var.create }

  name      = coalesce(each.value.name, "${local.name_prefix}r53-resolver-${var.account_name}-${var.project_name}-${each.key}")
  direction = each.value.direction

  dynamic "ip_address" {
    for_each = each.value.ip_addresses

    content {
      subnet_id = ip_address.value.subnet_id
      ip        = ip_address.value.ip
      ipv6      = ip_address.value.ipv6
    }
  }

  security_group_ids     = each.value.security_group_ids
  protocols              = length(each.value.protocols) > 0 ? each.value.protocols : null
  resolver_endpoint_type = each.value.resolver_endpoint_type

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = coalesce(each.value.name, "${local.name_prefix}r53-resolver-${var.account_name}-${var.project_name}-${each.key}")
    }
  )
}

# =============================================================================
# Route53 Resolver Rules
# =============================================================================

locals {
  resolver_endpoint_id_map = {
    for k, v in aws_route53_resolver_endpoint.this : k => v.id
  }

  # Expand resolver rules with VPC associations into individual rule-vpc pairs
  resolver_rule_vpc_associations = merge([
    for rule_key, rule in var.resolver_rules : {
      for vpc_id in rule.vpc_ids :
      "${rule_key}-${vpc_id}" => {
        rule_key = rule_key
        vpc_id   = vpc_id
      }
    }
  ]...)
}

resource "aws_route53_resolver_rule" "this" {
  for_each = { for k, v in var.resolver_rules : k => v if var.create }

  name                 = coalesce(each.value.name, each.key)
  domain_name          = each.value.domain_name
  rule_type            = each.value.rule_type
  resolver_endpoint_id = each.value.rule_type == "FORWARD" ? coalesce(each.value.resolver_endpoint_id, try(local.resolver_endpoint_id_map[each.value.resolver_endpoint_key], null)) : null

  dynamic "target_ip" {
    for_each = each.value.target_ips

    content {
      ip       = target_ip.value.ip
      ipv6     = target_ip.value.ipv6
      port     = target_ip.value.port
      protocol = target_ip.value.protocol
    }
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = coalesce(each.value.name, "${local.name_prefix}r53-rule-${var.account_name}-${var.project_name}-${each.key}")
    }
  )
}

# =============================================================================
# Route53 Resolver Rule Associations
# =============================================================================

resource "aws_route53_resolver_rule_association" "this" {
  for_each = { for k, v in local.resolver_rule_vpc_associations : k => v if var.create }

  name             = each.key
  resolver_rule_id = aws_route53_resolver_rule.this[each.value.rule_key].id
  vpc_id           = each.value.vpc_id
}
