# =============================================================================
# General Configuration Variables
# =============================================================================

variable "create" {
  description = "Whether to create Route53 resources."
  type        = bool
  default     = true
}

variable "account_name" {
  description = "Account name for resource naming."
  type        = string

  validation {
    condition     = length(var.account_name) > 0 && length(var.account_name) <= 32
    error_message = "account_name debe tener entre 1 y 32 caracteres."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.account_name))
    error_message = "account_name solo puede contener letras minúsculas, números y guiones."
  }
}

variable "project_name" {
  description = "Project name for resource naming."
  type        = string

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 32
    error_message = "project_name debe tener entre 1 y 32 caracteres."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name solo puede contener letras minúsculas, números y guiones."
  }
}

variable "region_prefix" {
  description = "Region prefix for naming. If not provided, will be derived from current region."
  type        = string
  default     = null
}

variable "use_region_prefix" {
  description = "Whether to include the region prefix in resource names."
  type        = bool
  default     = true
}

variable "tags_common" {
  description = "Common tags applied to all resources that support tags."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to apply to all resources. Kept for backward compatibility; merged on top of tags_common."
  type        = map(string)
  default     = {}
}

# =============================================================================
# Hosted Zones
# =============================================================================

variable "zones" {
  description = <<-EOT
    Map of Route53 hosted zones to create.

    Each zone supports:
    - domain_name: The domain name for the hosted zone (e.g., "example.com")
    - comment: Optional comment for the hosted zone
    - force_destroy: Whether to destroy all records when destroying the zone
    - vpc: List of VPCs to associate (makes the zone private)
    - delegation_set_id: ID of an external reusable delegation set (public zones only)
    - delegation_set_key: Key of a delegation set created in this module (public zones only)
    - vpc_association_authorizations: Map of VPCs (usually in other accounts) authorized to be
      associated with this private zone (key = user-defined name)
    - ignore_vpc: Ignore changes to the VPC associations after creation (use when extra VPC
      associations are managed outside this module, e.g. cross-account). Changing it on an
      existing zone moves it between resource addresses (see Upgrade notes)
    - tags: Additional tags for this specific zone
  EOT
  type = map(object({
    domain_name   = string
    comment       = optional(string, "Managed by Terraform")
    force_destroy = optional(bool, false)
    vpc = optional(list(object({
      vpc_id     = string
      vpc_region = optional(string)
    })), [])
    delegation_set_id  = optional(string)
    delegation_set_key = optional(string)
    vpc_association_authorizations = optional(map(object({
      vpc_id     = string
      vpc_region = optional(string)
    })), {})
    ignore_vpc = optional(bool, false)
    tags       = optional(map(string), {})
  }))
  default = {}
}

# =============================================================================
# DNS Records
# =============================================================================

variable "records" {
  description = <<-EOT
    Map of Route53 records to create.

    Each record supports:
    - zone_key: Reference to a zone created in this module (key from zones variable)
    - zone_id: External zone ID (alternative to zone_key)
    - name: Record name (e.g., "www" or "www.example.com")
    - full_name: Full record name (takes precedence over name; the key is used when both are null)
    - type: Record type (A, AAAA, CNAME, MX, TXT, SRV, NS, CAA, etc.)
    - ttl: TTL in seconds (not used with alias records)
    - records: List of record values
    - alias: Alias record configuration (zone_id = "self" targets the record's own zone)
    - Routing policies: weighted, latency, failover, geolocation, geoproximity, cidr
    - health_check_id: External health check ID
    - health_check_key: Reference to a health check created in this module
    - set_identifier: Unique identifier for routing policy records
    - multivalue_answer: Enable multivalue answer routing
    - allow_overwrite: Allow overwriting existing records
    - tags: Not used (Route53 records do not support tags); kept for backward compatibility
  EOT
  type = map(object({
    zone_key  = optional(string)
    zone_id   = optional(string)
    name      = optional(string)
    full_name = optional(string)
    type      = string
    ttl       = optional(number)
    records   = optional(list(string))
    # Alias record
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, true)
    }))
    # Routing policies
    set_identifier = optional(string)
    weighted_routing_policy = optional(object({
      weight = number
    }))
    latency_routing_policy = optional(object({
      region = string
    }))
    failover_routing_policy = optional(object({
      type = string
    }))
    geolocation_routing_policy = optional(object({
      continent   = optional(string)
      country     = optional(string)
      subdivision = optional(string)
    }))
    geoproximity_routing_policy = optional(object({
      bias       = optional(number)
      aws_region = optional(string)
      coordinates = optional(list(object({
        latitude  = number
        longitude = number
      })))
      local_zone_group = optional(string)
    }))
    cidr_routing_policy = optional(object({
      collection_id = string
      location_name = string
    }))
    health_check_id   = optional(string)
    health_check_key  = optional(string)
    multivalue_answer = optional(bool)
    allow_overwrite   = optional(bool, false)
    tags              = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.records : v.zone_id != null || v.zone_key != null])
    error_message = "Cada record debe definir zone_id o zone_key."
  }

  validation {
    condition     = alltrue([for k, v in var.records : v.alias == null || v.records == null])
    error_message = "Un record con alias no puede definir records (ttl se ignora en los alias)."
  }
}

# =============================================================================
# Health Checks
# =============================================================================

variable "health_checks" {
  description = <<-EOT
    Map of Route53 health checks to create.

    Each health check supports:
    - type: Health check type (HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP, CALCULATED, CLOUDWATCH_METRIC, RECOVERY_CONTROL)
    - fqdn: Fully qualified domain name to check
    - ip_address: IP address to check
    - port: Port number
    - resource_path: Path for HTTP/HTTPS checks
    - failure_threshold: Number of consecutive failures before unhealthy
    - request_interval: Seconds between health checks (10 or 30)
    - search_string: String to search for in response body (for STR_MATCH types)
    - measure_latency: Whether to measure latency
    - invert_healthcheck: Whether to invert the health check status
    - disabled: Whether the health check is disabled
    - enable_sni: Whether to enable SNI for HTTPS checks
    - regions: List of AWS regions to check from
    - child_healthchecks: List of child health check IDs (for CALCULATED type)
    - child_health_threshold: Minimum healthy children (for CALCULATED type)
    - cloudwatch_alarm_name: CloudWatch alarm name (for CLOUDWATCH_METRIC type)
    - cloudwatch_alarm_region: CloudWatch alarm region (for CLOUDWATCH_METRIC type)
    - insufficient_data_health_status: Status when CloudWatch has insufficient data
    - routing_control_arn: ARN of the Route53 Application Recovery Controller routing control
    - reference_name: Reference name used as caller reference (ForceNew)
    - tags: Additional tags for this health check
  EOT
  type = map(object({
    type                            = string
    fqdn                            = optional(string)
    ip_address                      = optional(string)
    port                            = optional(number)
    resource_path                   = optional(string)
    failure_threshold               = optional(number, 3)
    request_interval                = optional(number, 30)
    search_string                   = optional(string)
    measure_latency                 = optional(bool, false)
    invert_healthcheck              = optional(bool, false)
    disabled                        = optional(bool, false)
    enable_sni                      = optional(bool)
    regions                         = optional(list(string))
    child_healthchecks              = optional(list(string))
    child_health_threshold          = optional(number)
    cloudwatch_alarm_name           = optional(string)
    cloudwatch_alarm_region         = optional(string)
    insufficient_data_health_status = optional(string)
    routing_control_arn             = optional(string)
    reference_name                  = optional(string)
    tags                            = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.health_checks : contains(
        ["HTTP", "HTTPS", "HTTP_STR_MATCH", "HTTPS_STR_MATCH", "TCP", "CALCULATED", "CLOUDWATCH_METRIC", "RECOVERY_CONTROL"],
        v.type
      )
    ])
    error_message = "type debe ser HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP, CALCULATED, CLOUDWATCH_METRIC o RECOVERY_CONTROL."
  }

  validation {
    condition     = alltrue([for k, v in var.health_checks : contains([10, 30], v.request_interval)])
    error_message = "request_interval debe ser 10 o 30."
  }
}

# =============================================================================
# Delegation Sets
# =============================================================================

variable "delegation_sets" {
  description = <<-EOT
    Map of Route53 reusable delegation sets to create.

    Each delegation set supports:
    - reference_name: A unique string to identify the delegation set
  EOT
  type = map(object({
    reference_name = optional(string)
  }))
  default = {}
}

# =============================================================================
# Resolver Endpoints
# =============================================================================

variable "resolver_endpoints" {
  description = <<-EOT
    Map of Route53 Resolver endpoints to create.

    Each resolver endpoint supports:
    - name: Friendly name for the resolver endpoint
    - direction: INBOUND or OUTBOUND
    - ip_addresses: List of subnet IDs and optional IP addresses
    - security_group_ids: List of security group IDs to associate
    - protocols: List of protocols (Do53, DoH, DoH-FIPS)
    - resolver_endpoint_type: IPV4, IPV6, or DUALSTACK
    - tags: Additional tags for this resolver endpoint
  EOT
  type = map(object({
    name      = optional(string)
    direction = string
    ip_addresses = list(object({
      subnet_id = string
      ip        = optional(string)
      ipv6      = optional(string)
    }))
    security_group_ids     = list(string)
    protocols              = optional(list(string), [])
    resolver_endpoint_type = optional(string)
    tags                   = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.resolver_endpoints : contains(["INBOUND", "OUTBOUND"], v.direction)])
    error_message = "direction debe ser INBOUND u OUTBOUND."
  }
}

# =============================================================================
# Resolver Rules
# =============================================================================

variable "resolver_rules" {
  description = <<-EOT
    Map of Route53 Resolver rules to create and associate with VPCs.

    Each resolver rule supports:
    - name: Friendly name for the resolver rule (default: module naming convention)
    - domain_name: DNS queries for this domain will be forwarded
    - rule_type: FORWARD, SYSTEM, or RECURSIVE
    - resolver_endpoint_key: Key reference to resolver endpoint in this module
    - resolver_endpoint_id: External resolver endpoint ID (alternative to key)
    - target_ips: List of target IP addresses for forwarding
    - vpc_associations: Map of VPC associations (key = user-defined name, value = VPC ID). Using a map ensures stable for_each keys.
    - tags: Additional tags for this resolver rule
  EOT
  type = map(object({
    name                  = optional(string)
    domain_name           = string
    rule_type             = string
    resolver_endpoint_key = optional(string)
    resolver_endpoint_id  = optional(string)
    target_ips = optional(list(object({
      ip       = string
      ipv6     = optional(string)
      port     = optional(number)
      protocol = optional(string)
    })), [])
    vpc_associations = optional(map(string), {})
    tags             = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.resolver_rules : contains(["FORWARD", "SYSTEM", "RECURSIVE"], v.rule_type)])
    error_message = "rule_type debe ser FORWARD, SYSTEM o RECURSIVE."
  }

  validation {
    condition = alltrue([
      for k, v in var.resolver_rules : v.rule_type != "FORWARD" || v.resolver_endpoint_id != null || v.resolver_endpoint_key != null
    ])
    error_message = "Las reglas FORWARD deben definir resolver_endpoint_id o resolver_endpoint_key."
  }
}
