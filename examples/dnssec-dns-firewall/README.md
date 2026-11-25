# DNSSEC + DNS Firewall Example

Shows the features added in v2.2.0:

- **DNSSEC** on a public hosted zone: the module creates a KMS key in `us-east-1`
  (`ECC_NIST_P256`, `SIGN_VERIFY`) with the Route53 DNSSEC key policy, a key-signing key
  and `aws_route53_hosted_zone_dnssec`. Publish the `dnssec_ds_records` output at your
  registrar to complete the chain of trust.
- **Resolver endpoint security group**: `create_security_group = true` creates a security
  group with TCP and UDP port 53 rules and attaches it to the endpoint.
- **Resolver DNS Firewall**: a shared domain list, a rule group with an inline-domain rule
  and a `domain_list_key` rule, and an association with the VPC.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

> Disabling DNSSEC: set `dnssec_signing_status = "NOT_SIGNING"` and remove the DS record
> from the parent zone before deleting the zone or the KSK.
