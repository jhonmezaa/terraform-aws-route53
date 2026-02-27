# =============================================================================
# Route53 Hosted Zones
# =============================================================================

resource "aws_route53_zone" "this" {
  for_each = { for k, v in var.zones : k => v if var.create }

  name              = each.value.domain_name
  comment           = each.value.comment
  force_destroy     = each.value.force_destroy
  delegation_set_id = length(each.value.vpc) == 0 ? each.value.delegation_set_id : null

  dynamic "vpc" {
    for_each = each.value.vpc

    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.vpc_region
    }
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.value.domain_name
    }
  )
}
