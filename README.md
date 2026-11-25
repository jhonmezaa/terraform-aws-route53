# Terraform AWS Route53 Module

Production-ready Terraform module for managing AWS Route53 hosted zones, DNS records, health checks, delegation sets, DNSSEC, resolver endpoints and Resolver DNS Firewall in a single unified module.

## Features

- **Hosted Zones**: Public and private zones with VPC associations
- **DNS Records**: All record types (A, AAAA, CNAME, MX, TXT, SRV, NS, CAA, etc.)
- **Alias Records**: Native support for AWS resource aliases (ALB, CloudFront, S3, API Gateway)
- **Routing Policies**: Weighted, latency, failover, geolocation, geoproximity, CIDR, and multivalue
- **Health Checks**: HTTP, HTTPS, TCP, calculated, and CloudWatch alarm-based checks
- **Delegation Sets**: Reusable delegation sets for consistent name servers
- **DNSSEC**: Key-signing keys and DNSSEC signing for public zones, with an optional KMS key (us-east-1) created by the module
- **Resolver Endpoints**: Inbound and outbound DNS resolver endpoints, with an optional security group (TCP/UDP 53) created by the module
- **Resolver DNS Firewall**: Domain lists, rule groups, rules, VPC associations and RAM sharing
- **Resolver Rules**: DNS forwarding rules with VPC associations
- **Cross-Resource References**: Records can reference zones and health checks created in the same module
- **Cross-Account Private Zones**: VPC association authorizations and `ignore_vpc` to keep externally managed associations
- **Regional Support**: Automatic region prefix mapping for 34 AWS regions
- **Input Validation**: Validations for names, enums and cross-references (`zone_key`, `health_check_key`, `delegation_set_key`, `resolver_endpoint_key`)

## Usage

### Basic Example - Public Zone with Records

```hcl
module "route53" {
  source = "github.com/jhonmezaa/terraform-aws-route53//route53?ref=v2.2.0"

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
  source = "github.com/jhonmezaa/terraform-aws-route53//route53?ref=v2.2.0"

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
  source = "github.com/jhonmezaa/terraform-aws-route53//route53?ref=v2.2.0"

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
  source = "github.com/jhonmezaa/terraform-aws-route53//route53?ref=v2.2.0"

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
  source = "github.com/jhonmezaa/terraform-aws-route53//route53?ref=v2.2.0"

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

### Cross-Account Private Zone

```hcl
module "route53" {
  source = "github.com/jhonmezaa/terraform-aws-route53//route53?ref=v2.2.0"

  account_name = "prod"
  project_name = "myapp"

  zones = {
    internal = {
      domain_name = "internal.example.com"
      vpc         = [{ vpc_id = "vpc-12345678" }]
      ignore_vpc  = true # keep associations created from other accounts
      vpc_association_authorizations = {
        shared = {
          vpc_id     = "vpc-87654321" # VPC in the other account
          vpc_region = "us-east-1"
        }
      }
    }
  }
}
```

The other account then creates the `aws_route53_zone_association` with the zone ID from `zone_ids`.

### DNSSEC

```hcl
module "route53" {
  source = "github.com/jhonmezaa/terraform-aws-route53//route53?ref=v2.2.0"

  account_name = "prod"
  project_name = "myapp"

  zones = {
    public = {
      domain_name   = "example.com"
      enable_dnssec = true
    }
  }

  # Optional: bring your own key (us-east-1, ECC_NIST_P256, SIGN_VERIFY) instead of
  # the one created by the module
  # dnssec_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/..."
}
```

Publish the `dnssec_ds_records` output at the registrar (or parent zone) to complete the
chain of trust. To disable DNSSEC, first set `dnssec_signing_status = "NOT_SIGNING"` and remove
the DS record from the parent.

### Resolver Endpoint with Security Group and DNS Firewall

```hcl
module "route53" {
  source = "github.com/jhonmezaa/terraform-aws-route53//route53?ref=v2.2.0"

  account_name = "prod"
  project_name = "myapp"

  resolver_endpoints = {
    inbound = {
      direction             = "INBOUND"
      create_security_group = true
      vpc_id                = "vpc-12345678"
      ip_addresses          = [{ subnet_id = "subnet-aaaa" }, { subnet_id = "subnet-bbbb" }]
      security_group_ingress_rules = {
        onprem = { cidr_ipv4 = "192.168.0.0/16" } # creates TCP and UDP 53 rules
      }
    }
  }

  firewall_domain_lists = {
    blocked = { domains = ["malware.example.", "*.phishing.example."] }
  }

  firewall_rule_groups = {
    main = {
      rules = {
        allow-corp = { priority = 100, action = "ALLOW", domains = ["corp.example.com."] }
        block-bad  = { priority = 200, action = "BLOCK", block_response = "NXDOMAIN", domain_list_key = "blocked" }
      }
      vpc_associations = {
        app = { vpc_id = "vpc-12345678", priority = 101 }
      }
    }
  }
}
```

### Using External Zone ID

```hcl
module "route53" {
  source = "github.com/jhonmezaa/terraform-aws-route53//route53?ref=v2.2.0"

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

| Name                | Description                                                       | Type          | Default | Required |
| ------------------- | ----------------------------------------------------------------- | ------------- | ------- | -------- |
| `create`            | Whether to create Route53 resources                               | `bool`        | `true`  | no       |
| `account_name`      | Account name for resource naming (1-32 chars, lowercase, hyphens) | `string`      | -       | yes      |
| `project_name`      | Project name for resource naming (1-32 chars, lowercase, hyphens) | `string`      | -       | yes      |
| `region_prefix`     | Region prefix for naming (auto-derived if not set)                | `string`      | `null`  | no       |
| `use_region_prefix` | Whether to include region prefix in resource names                | `bool`        | `true`  | no       |
| `tags_common`       | Common tags applied to all resources that support tags            | `map(string)` | `{}`    | no       |
| `tags`              | Additional tags (backward compatible, merged over `tags_common`)  | `map(string)` | `{}`    | no       |

### Hosted Zones

| Name    | Description                           | Type          | Default | Required |
| ------- | ------------------------------------- | ------------- | ------- | -------- |
| `zones` | Map of Route53 hosted zones to create | `map(object)` | `{}`    | no       |

Each zone object supports:

- `domain_name` (string, required) - Domain name for the zone
- `comment` (string) - Zone comment (default: "Managed by Terraform")
- `force_destroy` (bool) - Destroy records when zone is destroyed (default: false)
- `vpc` (list of objects) - VPCs to associate (makes zone private)
- `delegation_set_id` (string) - External delegation set ID (public zones only)
- `delegation_set_key` (string) - Key of a delegation set created in this module (public zones only)
- `vpc_association_authorizations` (map of objects: `vpc_id`, `vpc_region`) - VPCs (usually in other accounts) authorized to associate with this private zone
- `ignore_vpc` (bool) - Ignore changes to VPC associations after creation (default: false). See the Upgrade notes in the CHANGELOG before toggling it on an existing zone
- `enable_dnssec` (bool) - Enable DNSSEC signing (public zones only, default: false)
- `dnssec_kms_key_arn` (string) - KMS key for this zone's KSK (falls back to `dnssec_kms_key_arn`, then to the key created by the module)
- `dnssec_key_signing_key_name` (string) - KSK name, letters/numbers/underscores (default: `ksk_<domain with "_" instead of dots>`)
- `dnssec_key_signing_key_status` (string) - `ACTIVE` or `INACTIVE` (default: `ACTIVE`)
- `dnssec_signing_status` (string) - `SIGNING` or `NOT_SIGNING` (default: `SIGNING`)
- `tags` (map of string) - Additional tags

### DNS Records

| Name      | Description                      | Type          | Default | Required |
| --------- | -------------------------------- | ------------- | ------- | -------- |
| `records` | Map of Route53 records to create | `map(object)` | `{}`    | no       |

Each record object supports:

- `zone_key` (string) - Reference to zone in this module
- `zone_id` (string) - External zone ID
- `name` (string) - Record name
- `full_name` (string) - Full record name (takes precedence over `name`; the map key is used when both are null)
- `type` (string, required) - Record type (A, AAAA, CNAME, MX, TXT, etc.)
- `ttl` (number) - TTL in seconds
- `records` (list of strings) - Record values
- `alias` (object) - Alias record config (`name`, `zone_id`, `evaluate_target_health` default `true`). `zone_id = "self"` targets the record's own zone. `records` cannot be combined with `alias`; `ttl` is ignored
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

| Name            | Description                            | Type          | Default | Required |
| --------------- | -------------------------------------- | ------------- | ------- | -------- |
| `health_checks` | Map of Route53 health checks to create | `map(object)` | `{}`    | no       |

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
- `routing_control_arn` (string) - ARC routing control ARN (RECOVERY_CONTROL type)
- `reference_name` (string) - Caller reference name (forces replacement)
- `tags` (map of string) - Additional tags

### DNSSEC

| Name                                     | Description                                                                                                       | Type           | Default                    | Required |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------- | -------------- | -------------------------- | -------- |
| `create_dnssec_kms_key`                  | Create the DNSSEC KMS key (only when a zone enables DNSSEC without its own key and `dnssec_kms_key_arn` is null) | `bool`         | `true`                     | no       |
| `dnssec_kms_key_arn`                     | Existing KMS key ARN for DNSSEC (takes precedence over the created key)                                          | `string`       | `null`                     | no       |
| `dnssec_kms_key_description`             | Description of the created KMS key                                                                                | `string`       | `"Route53 DNSSEC KMS Key"` | no       |
| `dnssec_kms_key_aliases`                 | Aliases for the created KMS key (`alias/` added when missing)                                                     | `list(string)` | `[]`                       | no       |
| `dnssec_kms_key_deletion_window_in_days` | Deletion window of the created KMS key (7-30)                                                                     | `number`       | `30`                       | no       |
| `dnssec_kms_key_tags`                    | Additional tags for the created KMS key                                                                           | `map(string)`  | `{}`                       | no       |

### Delegation Sets

| Name              | Description                      | Type          | Default | Required |
| ----------------- | -------------------------------- | ------------- | ------- | -------- |
| `delegation_sets` | Map of delegation sets to create | `map(object)` | `{}`    | no       |

### Resolver Endpoints

| Name                 | Description                         | Type          | Default | Required |
| -------------------- | ----------------------------------- | ------------- | ------- | -------- |
| `resolver_endpoints` | Map of resolver endpoints to create | `map(object)` | `{}`    | no       |

Each resolver endpoint object supports `name`, `direction`, `ip_addresses`, `protocols`,
`resolver_endpoint_type`, `tags` and:

- `security_group_ids` (list of string) - Existing security groups (default: `[]`; required unless `create_security_group = true`)
- `create_security_group` (bool) - Create a security group for the endpoint (default: false)
- `vpc_id` (string) - VPC of the created security group (required with `create_security_group`)
- `security_group_name` (string) - Name of the created security group (default: naming convention; cannot start with `sg-`)
- `security_group_use_name_prefix` (bool) - Use the name as prefix (default: false)
- `security_group_description` (string) - Description of the created security group
- `security_group_ingress_rules` / `security_group_egress_rules` (map of objects) - Port 53 rules; each creates a TCP and a UDP rule. Set exactly one of `cidr_ipv4`, `cidr_ipv6`, `prefix_list_id`, `referenced_security_group_id`; optional `description`, `tags`
- `security_group_tags` (map of string) - Additional tags for the security group and its rules

### Resolver Rules

| Name             | Description                     | Type          | Default | Required |
| ---------------- | ------------------------------- | ------------- | ------- | -------- |
| `resolver_rules` | Map of resolver rules to create | `map(object)` | `{}`    | no       |

### Resolver DNS Firewall

| Name                    | Description                                                     | Type          | Default | Required |
| ----------------------- | --------------------------------------------------------------- | ------------- | ------- | -------- |
| `firewall_domain_lists` | Shared domain lists (`name`, `domains`, `tags`)                 | `map(object)` | `{}`    | no       |
| `firewall_rule_groups`  | Rule groups with their rules, VPC associations and RAM sharing  | `map(object)` | `{}`    | no       |

Each rule group supports `name`, `tags`, `ram_resource_share_arns` (map of RAM share ARNs),
`vpc_associations` (map of `vpc_id`, `priority` 101-9900, `name`, `mutation_protection`, `tags`) and
`rules` (map). Each rule sets `priority`, `action` (`ALLOW`, `BLOCK`, `ALERT`), exactly one of
`domains` (inline list, creates a dedicated domain list), `domain_list_key` or
`firewall_domain_list_id`, and optionally `name`, `block_response`, `block_override_dns_type`,
`block_override_domain`, `block_override_ttl`, `firewall_domain_redirection_action`, `q_type`,
`domain_list_name` and `tags` (inline domain list).

## Outputs

### Hosted Zones

| Name                        | Description                            |
| --------------------------- | -------------------------------------- |
| `zone_ids`                  | Map of zone key to zone ID             |
| `zone_arns`                 | Map of zone key to zone ARN            |
| `zone_name_servers`         | Map of zone key to name servers        |
| `zone_primary_name_servers` | Map of zone key to primary name server |
| `zone_names`                | Map of zone key to zone name           |
| `vpc_association_authorizations` | All created VPC association authorizations |

### Records

| Name           | Description                              |
| -------------- | ---------------------------------------- |
| `record_names` | Map of record key to record name         |
| `record_fqdns` | Map of record key to FQDN                |
| `records`      | All created records with full attributes |

### Health Checks

| Name                | Description                                    |
| ------------------- | ---------------------------------------------- |
| `health_check_ids`  | Map of health check key to ID                  |
| `health_check_arns` | Map of health check key to ARN                 |
| `health_checks`     | All created health checks with full attributes |

### Delegation Sets

| Name                          | Description                               |
| ----------------------------- | ----------------------------------------- |
| `delegation_set_ids`          | Map of delegation set key to ID           |
| `delegation_set_name_servers` | Map of delegation set key to name servers |
| `delegation_set_reference_names` | Map of delegation set key to reference name |

### Resolver

| Name                             | Description                                         |
| -------------------------------- | --------------------------------------------------- |
| `resolver_endpoint_ids`          | Map of resolver endpoint key to ID                  |
| `resolver_endpoint_arns`         | Map of resolver endpoint key to ARN                 |
| `resolver_endpoint_host_vpc_ids` | Map of resolver endpoint key to host VPC ID         |
| `resolver_endpoint_ip_addresses` | Map of resolver endpoint key to IP addresses        |
| `resolver_endpoints`             | All created resolver endpoints with full attributes |
| `resolver_rule_ids`              | Map of resolver rule key to ID                      |
| `resolver_rule_arns`             | Map of resolver rule key to ARN                     |
| `resolver_rules`                 | All created resolver rules with full attributes     |
| `resolver_rule_associations`     | All created resolver rule associations              |
| `resolver_endpoint_security_group_ids`  | Map of resolver endpoint key to created security group ID  |
| `resolver_endpoint_security_group_arns` | Map of resolver endpoint key to created security group ARN |

### DNSSEC

| Name                         | Description                                         |
| ---------------------------- | --------------------------------------------------- |
| `dnssec_kms_key_arn`         | ARN of the created DNSSEC KMS key (or `null`)       |
| `dnssec_kms_key_id`          | ID of the created DNSSEC KMS key (or `null`)        |
| `dnssec_kms_key_policy`      | Policy of the created DNSSEC KMS key (or `null`)    |
| `dnssec_key_signing_key_ids` | Map of zone key to KSK ID                           |
| `dnssec_ds_records`          | Map of zone key to DS record (publish in parent)    |
| `dnssec_digest_values`       | Map of zone key to KSK digest value                 |
| `dnssec_dnskey_records`      | Map of zone key to DNSKEY record                    |
| `dnssec_key_tags`            | Map of zone key to KSK key tag                      |
| `dnssec_public_keys`         | Map of zone key to KSK public key                   |

### Resolver DNS Firewall

| Name                                  | Description                                                     |
| ------------------------------------- | --------------------------------------------------------------- |
| `firewall_domain_list_ids`            | Map of domain list key (shared or `<group>-<rule>`) to ID       |
| `firewall_domain_list_arns`           | Map of domain list key (shared or `<group>-<rule>`) to ARN      |
| `firewall_rule_group_ids`             | Map of rule group key to ID                                     |
| `firewall_rule_group_arns`            | Map of rule group key to ARN                                    |
| `firewall_rule_group_share_status`    | Map of rule group key to share status                           |
| `firewall_rules`                      | All created firewall rules (key = `<group>-<rule>`)             |
| `firewall_rule_group_association_ids` | Map of `<group>-<association>` to association ID                |
| `firewall_ram_resource_associations`  | All created RAM resource associations                           |

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.3  |
| aws       | >= 6.0  |

## Examples

See the [examples](./examples) directory for complete usage examples:

- [Basic](./examples/basic) - Public hosted zone with A, CNAME, MX, and TXT records
- [Complete](./examples/complete) - Full-featured example with public/private zones, delegation set reference, cross-account authorization, alias records (including `self`), routing policies and health checks
- [DNSSEC + DNS Firewall](./examples/dnssec-dns-firewall) - DNSSEC-signed public zone, resolver endpoint with a module-managed security group and Resolver DNS Firewall

## Resource Naming

Health checks are named following the module convention:

```
{region_prefix}-r53-hc-{account_name}-{project_name}-{key}
```

Example: `ause1-r53-hc-prod-myapp-primary-web`

Resolver endpoints and resolver rules follow a similar pattern (truncated to 64 characters):

```
{region_prefix}-r53-resolver-{account_name}-{project_name}-{key}
{region_prefix}-r53-rule-{account_name}-{project_name}-{key}
{region_prefix}-r53-fw-rg-{account_name}-{project_name}-{key}          # firewall rule group
{region_prefix}-r53-fw-dl-{account_name}-{project_name}-{key}          # domain list (inline: {group}-{rule})
{region_prefix}-r53-fw-assoc-{account_name}-{project_name}-{group}-{key}
{region_prefix}-kms-dnssec-{account_name}-{project_name}               # DNSSEC KMS key Name tag
```

Resolver endpoint security groups: `{region_prefix}-sg-r53-resolver-{account_name}-{project_name}-{key}`
(without region prefix: `r53-resolver-sg-...`, since AWS rejects names starting with `sg-`).
DNSSEC key-signing keys default to `ksk_<domain_name>` with non-alphanumeric characters replaced
by `_` (AWS only allows letters, numbers and underscores). Firewall rules use the rule key as name.

Hosted zones use the domain name as `Name` tag. Every taggable resource gets
`merge(tags_common, tags, <resource tags>, { Name, ManagedBy = "Terraform" })`.
An explicit `name` overrides the generated one.

When `use_region_prefix = false`, the region prefix is omitted from names.

## License

MIT License - see [LICENSE](./LICENSE) for details.

## Author

Created and maintained by [Jhon Meza](https://github.com/jhonmezaa).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
