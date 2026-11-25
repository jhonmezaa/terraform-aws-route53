# =============================================================================
# Route53 Resolver Endpoints
# =============================================================================

locals {
  # Resolver endpoint and rule names are limited to 64 characters by AWS
  resolver_endpoint_names = {
    for k, v in var.resolver_endpoints : k => coalesce(
      v.name,
      substr("${local.name_prefix}r53-resolver-${var.account_name}-${var.project_name}-${k}", 0, 64)
    )
  }

  resolver_rule_names = {
    for k, v in var.resolver_rules : k => coalesce(
      v.name,
      substr("${local.name_prefix}r53-rule-${var.account_name}-${var.project_name}-${k}", 0, 64)
    )
  }
}

resource "aws_route53_resolver_endpoint" "this" {
  for_each = { for k, v in var.resolver_endpoints : k => v if var.create }

  name      = local.resolver_endpoint_names[each.key]
  direction = each.value.direction

  dynamic "ip_address" {
    for_each = each.value.ip_addresses

    content {
      subnet_id = ip_address.value.subnet_id
      ip        = ip_address.value.ip
      ipv6      = ip_address.value.ipv6
    }
  }

  security_group_ids     = concat(try([aws_security_group.resolver[each.key].id], []), each.value.security_group_ids)
  protocols              = length(each.value.protocols) > 0 ? each.value.protocols : null
  resolver_endpoint_type = each.value.resolver_endpoint_type

  tags = merge(
    local.common_tags,
    each.value.tags,
    {
      Name      = local.resolver_endpoint_names[each.key]
      ManagedBy = "Terraform"
    }
  )

  lifecycle {
    precondition {
      condition     = each.value.create_security_group || length(each.value.security_group_ids) > 0
      error_message = "El resolver endpoint \"${each.key}\" necesita security_group_ids o create_security_group = true."
    }
  }
}

# =============================================================================
# Resolver Endpoint Security Groups (optional, TCP/UDP 53)
# =============================================================================

locals {
  resolver_security_group_endpoints = {
    for k, v in var.resolver_endpoints : k => v if var.create && v.create_security_group
  }

  # AWS rejects security group names starting with "sg-", so without region
  # prefix the type goes after the service: r53-resolver-sg-{account}-{project}-{key}
  resolver_security_group_names = {
    for k, v in local.resolver_security_group_endpoints : k => coalesce(
      v.security_group_name,
      var.use_region_prefix
      ? "${local.name_prefix}sg-r53-resolver-${var.account_name}-${var.project_name}-${k}"
      : "r53-resolver-sg-${var.account_name}-${var.project_name}-${k}"
    )
  }

  # One entry per rule and protocol (key = <endpoint>-<rule>-<tcp|udp>)
  resolver_security_group_rules = merge(flatten([
    for endpoint_key, endpoint in local.resolver_security_group_endpoints : [
      for direction, rules in { ingress = endpoint.security_group_ingress_rules, egress = endpoint.security_group_egress_rules } : {
        for pair in setproduct(keys(rules), ["tcp", "udp"]) :
        "${endpoint_key}-${pair[0]}-${pair[1]}" => merge(rules[pair[0]], {
          endpoint_key = endpoint_key
          rule_key     = pair[0]
          direction    = direction
          protocol     = pair[1]
        })
      }
    ]
  ])...)
}

resource "aws_security_group" "resolver" {
  for_each = local.resolver_security_group_endpoints

  name        = each.value.security_group_use_name_prefix ? null : local.resolver_security_group_names[each.key]
  name_prefix = each.value.security_group_use_name_prefix ? "${local.resolver_security_group_names[each.key]}-" : null
  description = coalesce(each.value.security_group_description, "Route53 Resolver endpoint ${local.resolver_endpoint_names[each.key]}")
  vpc_id      = each.value.vpc_id

  tags = merge(
    local.common_tags,
    each.value.tags,
    each.value.security_group_tags,
    {
      Name      = local.resolver_security_group_names[each.key]
      ManagedBy = "Terraform"
    }
  )

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = each.value.vpc_id != null
      error_message = "El resolver endpoint \"${each.key}\" usa create_security_group = true y debe definir vpc_id."
    }
  }
}

resource "aws_vpc_security_group_ingress_rule" "resolver" {
  for_each = { for k, v in local.resolver_security_group_rules : k => v if v.direction == "ingress" }

  security_group_id            = aws_security_group.resolver[each.value.endpoint_key].id
  description                  = each.value.description
  ip_protocol                  = each.value.protocol
  from_port                    = 53
  to_port                      = 53
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id

  tags = merge(
    local.common_tags,
    var.resolver_endpoints[each.value.endpoint_key].security_group_tags,
    each.value.tags,
    {
      Name      = "${local.resolver_security_group_names[each.value.endpoint_key]}-${each.value.rule_key}-${each.value.protocol}"
      ManagedBy = "Terraform"
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "resolver" {
  for_each = { for k, v in local.resolver_security_group_rules : k => v if v.direction == "egress" }

  security_group_id            = aws_security_group.resolver[each.value.endpoint_key].id
  description                  = each.value.description
  ip_protocol                  = each.value.protocol
  from_port                    = 53
  to_port                      = 53
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  prefix_list_id               = each.value.prefix_list_id
  referenced_security_group_id = each.value.referenced_security_group_id

  tags = merge(
    local.common_tags,
    var.resolver_endpoints[each.value.endpoint_key].security_group_tags,
    each.value.tags,
    {
      Name      = "${local.resolver_security_group_names[each.value.endpoint_key]}-${each.value.rule_key}-${each.value.protocol}"
      ManagedBy = "Terraform"
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
  # Uses user-defined keys from vpc_associations map for stable for_each keys
  resolver_rule_vpc_associations = merge([
    for rule_key, rule in var.resolver_rules : {
      for assoc_key, vpc_id in rule.vpc_associations :
      "${rule_key}-${assoc_key}" => {
        rule_key = rule_key
        vpc_id   = vpc_id
      }
    }
  ]...)
}

resource "aws_route53_resolver_rule" "this" {
  for_each = { for k, v in var.resolver_rules : k => v if var.create }

  name                 = local.resolver_rule_names[each.key]
  domain_name          = each.value.domain_name
  rule_type            = each.value.rule_type
  resolver_endpoint_id = each.value.rule_type == "FORWARD" ? try(coalesce(each.value.resolver_endpoint_id, try(local.resolver_endpoint_id_map[each.value.resolver_endpoint_key], null)), null) : null

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
    local.common_tags,
    each.value.tags,
    {
      Name      = local.resolver_rule_names[each.key]
      ManagedBy = "Terraform"
    }
  )

  lifecycle {
    precondition {
      condition     = each.value.resolver_endpoint_key == null || contains(keys(var.resolver_endpoints), coalesce(each.value.resolver_endpoint_key, "-"))
      error_message = "La regla \"${each.key}\" referencia un resolver_endpoint_key que no existe en var.resolver_endpoints."
    }
  }
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
