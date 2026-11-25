# =============================================================================
# Route53 Resolver DNS Firewall
# =============================================================================

locals {
  # Resolver DNS Firewall names are limited to 64 characters by AWS
  firewall_domain_list_names = {
    for k, v in var.firewall_domain_lists : k => coalesce(
      v.name,
      substr("${local.name_prefix}r53-fw-dl-${var.account_name}-${var.project_name}-${k}", 0, 64)
    )
  }

  firewall_rule_group_names = {
    for k, v in var.firewall_rule_groups : k => coalesce(
      v.name,
      substr("${local.name_prefix}r53-fw-rg-${var.account_name}-${var.project_name}-${k}", 0, 64)
    )
  }

  # Flatten rules (key = <group_key>-<rule_key>)
  firewall_rules = merge([
    for group_key, group in var.firewall_rule_groups : {
      for rule_key, rule in group.rules :
      "${group_key}-${rule_key}" => merge(rule, {
        group_key = group_key
        rule_key  = rule_key
      })
    }
  ]...)

  # Rules with inline `domains` get their own domain list (1:1, as in the official module)
  firewall_inline_domain_lists = {
    for k, v in local.firewall_rules : k => v if v.domains != null
  }

  firewall_inline_domain_list_names = {
    for k, v in local.firewall_inline_domain_lists : k => coalesce(
      v.domain_list_name,
      substr("${local.name_prefix}r53-fw-dl-${var.account_name}-${var.project_name}-${k}", 0, 64)
    )
  }

  firewall_rule_group_associations = merge([
    for group_key, group in var.firewall_rule_groups : {
      for assoc_key, assoc in group.vpc_associations :
      "${group_key}-${assoc_key}" => merge(assoc, { group_key = group_key })
    }
  ]...)

  firewall_rule_group_association_names = {
    for k, v in local.firewall_rule_group_associations : k => coalesce(
      v.name,
      substr("${local.name_prefix}r53-fw-assoc-${var.account_name}-${var.project_name}-${k}", 0, 64)
    )
  }

  firewall_ram_resource_associations = merge([
    for group_key, group in var.firewall_rule_groups : {
      for share_key, share_arn in group.ram_resource_share_arns :
      "${group_key}-${share_key}" => {
        group_key          = group_key
        resource_share_arn = share_arn
      }
    }
  ]...)
}

# -----------------------------------------------------------------------------
# Domain lists (shared, referenced by rules through domain_list_key)
# -----------------------------------------------------------------------------

resource "aws_route53_resolver_firewall_domain_list" "this" {
  for_each = { for k, v in var.firewall_domain_lists : k => v if var.create }

  name    = local.firewall_domain_list_names[each.key]
  domains = each.value.domains

  tags = merge(
    local.common_tags,
    each.value.tags,
    {
      Name      = local.firewall_domain_list_names[each.key]
      ManagedBy = "Terraform"
    }
  )
}

# Inline domain lists (one per rule that defines `domains`)
resource "aws_route53_resolver_firewall_domain_list" "rule" {
  for_each = { for k, v in local.firewall_inline_domain_lists : k => v if var.create }

  name    = local.firewall_inline_domain_list_names[each.key]
  domains = each.value.domains

  tags = merge(
    local.common_tags,
    var.firewall_rule_groups[each.value.group_key].tags,
    each.value.tags,
    {
      Name      = local.firewall_inline_domain_list_names[each.key]
      ManagedBy = "Terraform"
    }
  )
}

# -----------------------------------------------------------------------------
# Rule groups
# -----------------------------------------------------------------------------

resource "aws_route53_resolver_firewall_rule_group" "this" {
  for_each = { for k, v in var.firewall_rule_groups : k => v if var.create }

  name = local.firewall_rule_group_names[each.key]

  tags = merge(
    local.common_tags,
    each.value.tags,
    {
      Name      = local.firewall_rule_group_names[each.key]
      ManagedBy = "Terraform"
    }
  )
}

# -----------------------------------------------------------------------------
# Rules
# -----------------------------------------------------------------------------

resource "aws_route53_resolver_firewall_rule" "this" {
  for_each = { for k, v in local.firewall_rules : k => v if var.create }

  name                   = substr(coalesce(each.value.name, each.value.rule_key), 0, 64)
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.this[each.value.group_key].id
  firewall_domain_list_id = try(coalesce(
    each.value.firewall_domain_list_id,
    try(aws_route53_resolver_firewall_domain_list.rule[each.key].id, null),
    try(aws_route53_resolver_firewall_domain_list.this[each.value.domain_list_key].id, null)
  ), null)

  priority                           = each.value.priority
  action                             = each.value.action
  block_response                     = each.value.block_response
  block_override_dns_type            = each.value.block_override_dns_type
  block_override_domain              = each.value.block_override_domain
  block_override_ttl                 = each.value.block_override_ttl
  firewall_domain_redirection_action = each.value.firewall_domain_redirection_action
  q_type                             = each.value.q_type

  lifecycle {
    precondition {
      condition     = each.value.domain_list_key == null || contains(keys(var.firewall_domain_lists), coalesce(each.value.domain_list_key, "-"))
      error_message = "La regla de firewall \"${each.key}\" referencia un domain_list_key que no existe en var.firewall_domain_lists."
    }
  }
}

# -----------------------------------------------------------------------------
# VPC associations
# -----------------------------------------------------------------------------

resource "aws_route53_resolver_firewall_rule_group_association" "this" {
  for_each = { for k, v in local.firewall_rule_group_associations : k => v if var.create }

  name                   = local.firewall_rule_group_association_names[each.key]
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.this[each.value.group_key].id
  vpc_id                 = each.value.vpc_id
  priority               = each.value.priority
  mutation_protection    = each.value.mutation_protection

  tags = merge(
    local.common_tags,
    var.firewall_rule_groups[each.value.group_key].tags,
    each.value.tags,
    {
      Name      = local.firewall_rule_group_association_names[each.key]
      ManagedBy = "Terraform"
    }
  )
}

# -----------------------------------------------------------------------------
# RAM resource associations (share a rule group with other accounts)
# -----------------------------------------------------------------------------

resource "aws_ram_resource_association" "firewall_rule_group" {
  for_each = { for k, v in local.firewall_ram_resource_associations : k => v if var.create }

  resource_arn       = aws_route53_resolver_firewall_rule_group.this[each.value.group_key].arn
  resource_share_arn = each.value.resource_share_arn
}
