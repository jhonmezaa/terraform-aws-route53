# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
