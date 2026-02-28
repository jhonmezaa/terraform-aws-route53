# =============================================================================
# Route53 Health Checks
# =============================================================================

resource "aws_route53_health_check" "this" {
  for_each = { for k, v in var.health_checks : k => v if var.create }

  # Common settings
  type = each.value.type

  # request_interval and failure_threshold are only valid for endpoint-based health checks
  # (HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP), not for CALCULATED, CLOUDWATCH_METRIC,
  # or RECOVERY_CONTROL types.
  request_interval  = contains(["CALCULATED", "CLOUDWATCH_METRIC", "RECOVERY_CONTROL"], each.value.type) ? null : each.value.request_interval
  failure_threshold = contains(["CALCULATED", "CLOUDWATCH_METRIC", "RECOVERY_CONTROL"], each.value.type) ? null : each.value.failure_threshold

  measure_latency    = each.value.measure_latency
  invert_healthcheck = each.value.invert_healthcheck
  disabled           = each.value.disabled
  reference_name     = each.value.reference_name

  # HTTP/HTTPS/TCP settings
  fqdn          = each.value.fqdn
  ip_address    = each.value.ip_address
  port          = each.value.port
  resource_path = each.value.resource_path
  search_string = each.value.search_string
  enable_sni    = each.value.enable_sni
  regions       = each.value.regions

  # Calculated health check settings
  child_healthchecks     = each.value.child_healthchecks
  child_health_threshold = each.value.child_health_threshold

  # CloudWatch alarm settings
  cloudwatch_alarm_name           = each.value.cloudwatch_alarm_name
  cloudwatch_alarm_region         = each.value.cloudwatch_alarm_region
  insufficient_data_health_status = each.value.insufficient_data_health_status

  # Recovery control settings
  routing_control_arn = each.value.routing_control_arn

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = "${local.name_prefix}r53-hc-${var.account_name}-${var.project_name}-${each.key}"
    }
  )
}
