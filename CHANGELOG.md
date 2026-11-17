# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v2.1.0] - 2026-11-17

### Added

- `tags_common` variable (project convention); merged with the existing `tags` variable, which is kept for backward compatibility
- `ManagedBy = "Terraform"` tag on every taggable resource
- `zones.delegation_set_key` to reference a delegation set created in the same module (`delegation_set_id` still takes precedence)
- `zones.vpc_association_authorizations` (`aws_route53_vpc_association_authorization`) for cross-account private zone associations, and `vpc_association_authorizations` output
- `zones.ignore_vpc` (default `false`): creates the zone in `aws_route53_zone.ignore_vpc`, which ignores later changes to VPC associations managed outside the module
- `alias.zone_id = "self"` to point an alias to the record's own hosted zone
- Outputs `delegation_set_reference_names` and `resolver_endpoint_ip_addresses`
- Region prefixes for `ap-east-2`, `ap-southeast-5`, `ap-southeast-6`, `ap-southeast-7` and `mx-central-1`
- Validations (error messages in Spanish): health check `type` and `request_interval`, resolver endpoint `direction`, resolver rule `rule_type`, FORWARD rules require an endpoint, records require `zone_id` or `zone_key`, alias records cannot define `records`
- Preconditions that fail the plan when `zone_key`, `health_check_key`, `delegation_set_key` or `resolver_endpoint_key` reference a missing key (previously a typo in `health_check_key` or `delegation_set_key` was silently ignored)

### Changed

- Resolver rules without an explicit `name` now use the module naming convention (`{prefix}-r53-rule-{account}-{project}-{key}`) instead of the map key, matching their `Name` tag
- Resolver endpoint and rule generated names are truncated to 64 characters (AWS limit)
- `account_name` / `project_name` validation messages translated to Spanish
- Removed unused `data.aws_caller_identity` and `zone_name_map` local
- Examples: version files renamed to `versions.tf`; `complete` shows a delegation set key, cross-account authorization, `ignore_vpc` and a `self` alias; both use `tags_common`

### Upgrade notes

- Resolver rules created without `name` are renamed in place (no replacement) to the convention name. Set `name = "<key>"` to keep the previous name.
- The new `ManagedBy` tag (and any `tags_common`) produces an in-place tag update on existing resources.
- Setting `ignore_vpc = true` on an existing zone moves it to a different address. Run `terraform state mv 'module.<name>.aws_route53_zone.this["<key>"]' 'module.<name>.aws_route53_zone.ignore_vpc["<key>"]'` before applying to avoid recreating the zone.

## [v2.0.5] - 2026-10-27

### Changed

- Normalize CHANGELOG: preamble moved to the top, all headings use the `## [vX.Y.Z] - YYYY-MM-DD` format, entries sorted by version (newest first)
- Add missing entries for v2.0.0 and v2.0.1, reconstructed from git history

## [v2.0.4] - 2026-10-27

### Fixed

- Replace deprecated `data.aws_region.current.id` with `data.aws_region.current.region` (deprecated in AWS provider v6) in module locals

## [v2.0.3] - 2026-10-27

### Changed

- Use minimum-only version constraints in the reusable module, following HashiCorp guidance for shared modules: AWS provider `~> 6.0` -> `>= 6.0`
- Set module `required_version` to `>= 1.3` (was `~> 1.0`): the module uses `optional()` object type attributes (with defaults), which require Terraform 1.3; no newer features (`moved`/`import`/`check`/`removed`, cross-variable validations, provider-defined functions, ephemeral resources) are used
- Examples (root modules) keep pessimistic constraints: `required_version` `~> 1.3`, AWS provider `~> 6.0`
- Update Terraform and provider requirements in README

## [v2.0.2] - 2026-04-25

### Changed

- Update README documentation and CHANGELOG formatting

## [v2.0.1] - 2026-02-28

### Changed

- Update README and CHANGELOG documentation

## [v2.0.0] - 2026-02-28

### BREAKING CHANGES

- `resolver_rules.vpc_ids` (list) replaced with `resolver_rules.vpc_associations` (`map(string)`) to avoid unknown `for_each` keys when VPC IDs are computed at apply time

### Fixed

- Health checks: `request_interval` and `failure_threshold` are set to `null` for `CALCULATED`, `CLOUDWATCH_METRIC` and `RECOVERY_CONTROL` types, since the AWS API rejects these parameters for non-endpoint health checks

## [v1.0.0] - 2026-02-27

### Added

#### Core Features

- **Hosted Zones**: Create public and private Route53 hosted zones with VPC associations
- **DNS Records**: Full support for all DNS record types (A, AAAA, CNAME, MX, TXT, SRV, NS, CAA, etc.)
- **Alias Records**: Support for alias records pointing to AWS resources (ALB, CloudFront, S3, etc.)
- **Health Checks**: HTTP, HTTPS, TCP, calculated, and CloudWatch alarm-based health checks
- **Delegation Sets**: Reusable delegation sets for consistent name servers across zones
- **Resolver Endpoints**: Route53 Resolver inbound and outbound endpoints
- **Resolver Rules**: DNS forwarding rules with VPC associations

#### DNS Routing Policies

- **Weighted Routing**: Distribute traffic across multiple resources by weight
- **Latency Routing**: Route to the lowest latency endpoint
- **Failover Routing**: Active-passive failover with health check integration
- **Geolocation Routing**: Route based on geographic location of the requester
- **Geoproximity Routing**: Route based on geographic proximity with bias
- **CIDR Routing**: Route based on client CIDR blocks
- **Multivalue Answer**: Return multiple healthy IPs

#### Cross-Resource References

- Records can reference zones created in the same module via `zone_key`
- Records can reference health checks created in the same module via `health_check_key`
- Resolver rules can reference endpoints created in the same module via `resolver_endpoint_key`

#### Naming Convention

- Automatic region prefix mapping for 29 AWS regions
- Health check naming: `{region_prefix}-r53-hc-{account_name}-{project_name}-{key}`
- Resolver naming: `{region_prefix}-r53-resolver-{account_name}-{project_name}-{key}`
- Configurable region prefix with `use_region_prefix` toggle

#### Validation

- Account name validation (1-32 chars, lowercase alphanumeric with hyphens)
- Project name validation (1-32 chars, lowercase alphanumeric with hyphens)

#### Examples

- **basic**: Public hosted zone with A, CNAME, MX, and TXT records
- **complete**: Full-featured example with public/private zones, alias records, routing policies, health checks, and delegation sets

#### Documentation

- Comprehensive README with usage examples
- Complete variable and output documentation
- CHANGELOG following Keep a Changelog format

### Technical Details

- **Terraform Version**: ~> 1.0
- **AWS Provider Version**: ~> 6.0
- **Breaking Changes**: None (initial release)
- Uses `for_each` pattern for all resources
- Dynamic blocks for optional features (alias, routing policies, VPC associations)
- Unified single-module design (no submodules)

---

[v1.0.0]: https://github.com/jhonmezaa/terraform-aws-route53/releases/tag/v1.0.0
