# Terraform AWS Route53 Module

Production-ready Terraform module for managing AWS Route53 hosted zones, DNS records, health checks, delegation sets, and resolver endpoints in a single unified module.

## Features

- **Hosted Zones**: Public and private zones with VPC associations
- **DNS Records**: All record types (A, AAAA, CNAME, MX, TXT, SRV, NS, CAA, etc.)
- **Alias Records**: Native support for AWS resource aliases (ALB, CloudFront, S3, API Gateway)
- **Routing Policies**: Weighted, latency, failover, geolocation, geoproximity, CIDR, and multivalue
- **Health Checks**: HTTP, HTTPS, TCP, calculated, and CloudWatch alarm-based checks
- **Delegation Sets**: Reusable delegation sets for consistent name servers
- **Resolver Endpoints**: Inbound and outbound DNS resolver endpoints
- **Resolver Rules**: DNS forwarding rules with VPC associations
- **Cross-Resource References**: Records can reference zones and health checks created in the same module
- **Regional Support**: Automatic region prefix mapping for 29 AWS regions
- **Input Validation**: Comprehensive variable validations for account/project names

## Usage

### Basic Example - Public Zone with Records

```hcl
module "route53" {
  source = "./route53"

  account_name = "prod"
  project_name = "myapp"

  zones = {
    main = {
      domain_name = "example.com"
      comment     = "Public zone for myapp"
    }
  }

  records = {
    www = {
      zone_key = "main"
      name     = "www.example.com"
      type     = "A"
      ttl      = 300
      records  = ["203.0.113.1"]
    }

    mail = {
      zone_key  = "main"
      full_name = "example.com"
      type      = "MX"
      ttl       = 3600
      records   = [
        "1 aspmx.l.google.com",
        "5 alt1.aspmx.l.google.com",
      ]
    }
  }
}
```

### Alias Records

```hcl
module "route53" {
  source = "./route53"

  account_name = "prod"
  project_name = "myapp"

  zones = {
    main = {
      domain_name = "example.com"
    }
  }

  records = {
    app = {
      zone_key = "main"
      name     = "app.example.com"
      type     = "A"
      alias = {
        name                   = "my-alb-123.us-east-1.elb.amazonaws.com"
        zone_id                = "Z35SXDOTRQ7X7K"
        evaluate_target_health = true
      }
    }
  }
}
```

### Private Hosted Zone

```hcl
module "route53" {
  source = "./route53"

  account_name = "prod"
  project_name = "myapp"

  zones = {
    internal = {
      domain_name = "internal.example.com"
      vpc = [
        {
          vpc_id     = "vpc-12345678"
          vpc_region = "us-east-1"
        }
      ]
    }
  }

  records = {
    api = {
      zone_key = "internal"
      name     = "api.internal.example.com"
      type     = "A"
      ttl      = 300
      records  = ["10.0.1.100"]
    }
  }
}
```

### Weighted Routing with Health Checks

```hcl
module "route53" {
  source = "./route53"

  account_name = "prod"
  project_name = "myapp"

  zones = {
    main = {
      domain_name = "example.com"
    }
  }

  health_checks = {
    primary = {
      type              = "HTTPS"
      fqdn              = "primary.example.com"
      port              = 443
      resource_path     = "/health"
      failure_threshold = 3
      request_interval  = 30
    }
  }

  records = {
    blue = {
      zone_key         = "main"
      name             = "app.example.com"
      type             = "A"
      ttl              = 60
      records          = ["203.0.113.1"]
      set_identifier   = "blue"
      health_check_key = "primary"
      weighted_routing_policy = {
        weight = 90
      }
    }

    green = {
      zone_key       = "main"
      name           = "app.example.com"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.2"]
      set_identifier = "green"
      weighted_routing_policy = {
        weight = 10
      }
    }
  }
}
```

### Failover Routing

```hcl
module "route53" {
  source = "./route53"

  account_name = "prod"
  project_name = "myapp"

  zones = {
    main = {
      domain_name = "example.com"
    }
  }

  health_checks = {
    primary = {
      type              = "HTTPS"
      fqdn              = "primary.example.com"
      port              = 443
      resource_path     = "/health"
      failure_threshold = 3
      request_interval  = 30
    }
  }

  records = {
    primary = {
      zone_key         = "main"
      name             = "app.example.com"
      type             = "A"
      ttl              = 60
      records          = ["203.0.113.1"]
      set_identifier   = "primary"
      health_check_key = "primary"
      failover_routing_policy = {
        type = "PRIMARY"
      }
    }

    secondary = {
      zone_key       = "main"
      name           = "app.example.com"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.2"]
      set_identifier = "secondary"
      failover_routing_policy = {
        type = "SECONDARY"
      }
    }
  }
}
```

### Using External Zone ID

```hcl
module "route53" {
  source = "./route53"

  account_name = "prod"
  project_name = "myapp"

  records = {
    www = {
      zone_id = "Z1234567890ABC"
      name    = "www.example.com"
      type    = "A"
      ttl     = 300
      records = ["203.0.113.1"]
    }
  }
}
```

## Inputs

### General Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `create` | Whether to create Route53 resources | `bool` | `true` | no |
| `account_name` | Account name for resource naming (1-32 chars, lowercase, hyphens) | `string` | - | yes |
| `project_name` | Project name for resource naming (1-32 chars, lowercase, hyphens) | `string` | - | yes |
| `region_prefix` | Region prefix for naming (auto-derived if not set) | `string` | `null` | no |
| `use_region_prefix` | Whether to include region prefix in resource names | `bool` | `true` | no |
| `tags` | Additional tags to apply to all resources | `map(string)` | `{}` | no |

### Hosted Zones

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `zones` | Map of Route53 hosted zones to create | `map(object)` | `{}` | no |

Each zone object supports:
- `domain_name` (string, required) - Domain name for the zone
- `comment` (string) - Zone comment (default: "Managed by Terraform")
- `force_destroy` (bool) - Destroy records when zone is destroyed (default: false)
- `vpc` (list of objects) - VPCs to associate (makes zone private)
- `delegation_set_id` (string) - Delegation set ID for the zone
- `tags` (map of string) - Additional tags

### DNS Records

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `records` | Map of Route53 records to create | `map(object)` | `{}` | no |

Each record object supports:
- `zone_key` (string) - Reference to zone in this module
- `zone_id` (string) - External zone ID
- `name` (string) - Record name
- `full_name` (string) - Full record name (overrides name)
- `type` (string, required) - Record type (A, AAAA, CNAME, MX, TXT, etc.)
- `ttl` (number) - TTL in seconds
- `records` (list of strings) - Record values
- `alias` (object) - Alias record config (name, zone_id, evaluate_target_health)
- `set_identifier` (string) - Routing policy identifier
- `weighted_routing_policy` (object) - Weighted routing config
- `latency_routing_policy` (object) - Latency routing config
- `failover_routing_policy` (object) - Failover routing config
- `geolocation_routing_policy` (object) - Geolocation routing config
- `geoproximity_routing_policy` (object) - Geoproximity routing config
- `cidr_routing_policy` (object) - CIDR routing config
- `health_check_id` (string) - External health check ID
- `health_check_key` (string) - Reference to health check in this module
- `multivalue_answer` (bool) - Enable multivalue answer routing
- `allow_overwrite` (bool) - Allow overwriting existing records

### Health Checks

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `health_checks` | Map of Route53 health checks to create | `map(object)` | `{}` | no |

Each health check object supports:
- `type` (string, required) - Check type (HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP, CALCULATED, CLOUDWATCH_METRIC, RECOVERY_CONTROL)
- `fqdn` (string) - FQDN to check
- `ip_address` (string) - IP address to check
- `port` (number) - Port number
- `resource_path` (string) - HTTP path to check
- `failure_threshold` (number) - Failures before unhealthy (default: 3)
- `request_interval` (number) - Seconds between checks (default: 30)
- `search_string` (string) - String to find in response
- `measure_latency` (bool) - Measure latency (default: false)
- `invert_healthcheck` (bool) - Invert status (default: false)
- `disabled` (bool) - Disable the check (default: false)
- `enable_sni` (bool) - Enable SNI for HTTPS
- `regions` (list of strings) - AWS regions to check from
- `child_healthchecks` (list of strings) - Child check IDs (CALCULATED type)
- `child_health_threshold` (number) - Minimum healthy children (CALCULATED type)
- `cloudwatch_alarm_name` (string) - CloudWatch alarm (CLOUDWATCH_METRIC type)
- `cloudwatch_alarm_region` (string) - Alarm region (CLOUDWATCH_METRIC type)
- `insufficient_data_health_status` (string) - Status on insufficient data

### Delegation Sets

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `delegation_sets` | Map of delegation sets to create | `map(object)` | `{}` | no |

### Resolver Endpoints

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `resolver_endpoints` | Map of resolver endpoints to create | `map(object)` | `{}` | no |

### Resolver Rules

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `resolver_rules` | Map of resolver rules to create | `map(object)` | `{}` | no |

## Outputs

### Hosted Zones

| Name | Description |
|------|-------------|
| `zone_ids` | Map of zone key to zone ID |
| `zone_arns` | Map of zone key to zone ARN |
| `zone_name_servers` | Map of zone key to name servers |
| `zone_primary_name_servers` | Map of zone key to primary name server |
| `zone_names` | Map of zone key to zone name |

### Records

| Name | Description |
|------|-------------|
| `record_names` | Map of record key to record name |
| `record_fqdns` | Map of record key to FQDN |
| `records` | All created records with full attributes |

### Health Checks

| Name | Description |
|------|-------------|
| `health_check_ids` | Map of health check key to ID |
| `health_check_arns` | Map of health check key to ARN |
| `health_checks` | All created health checks with full attributes |

### Delegation Sets

| Name | Description |
|------|-------------|
| `delegation_set_ids` | Map of delegation set key to ID |
| `delegation_set_name_servers` | Map of delegation set key to name servers |

### Resolver

| Name | Description |
|------|-------------|
| `resolver_endpoint_ids` | Map of resolver endpoint key to ID |
| `resolver_endpoint_arns` | Map of resolver endpoint key to ARN |
| `resolver_endpoint_host_vpc_ids` | Map of resolver endpoint key to host VPC ID |
| `resolver_endpoints` | All created resolver endpoints with full attributes |
| `resolver_rule_ids` | Map of resolver rule key to ID |
| `resolver_rule_arns` | Map of resolver rule key to ARN |
| `resolver_rules` | All created resolver rules with full attributes |
| `resolver_rule_associations` | All created resolver rule associations |

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.0 |
| aws | ~> 6.0 |

## Examples

See the [examples](./examples) directory for complete usage examples:

- [Basic](./examples/basic) - Public hosted zone with A, CNAME, MX, and TXT records
- [Complete](./examples/complete) - Full-featured example with public/private zones, alias records, all routing policies, health checks, and delegation sets

## Resource Naming

Health checks are named following the module convention:
```
{region_prefix}-r53-hc-{account_name}-{project_name}-{key}
```

Example: `ause1-r53-hc-prod-myapp-primary-web`

Resolver endpoints follow a similar pattern:
```
{region_prefix}-r53-resolver-{account_name}-{project_name}-{key}
```

When `use_region_prefix = false`, the region prefix is omitted from names.

## License

MIT License - see [LICENSE](./LICENSE) for details.

## Author

Created and maintained by [Jhon Meza](https://github.com/jhonmezaa).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
