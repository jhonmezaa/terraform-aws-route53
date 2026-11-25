data "aws_region" "current" {}

# Only read when the module creates the DNSSEC KMS key (key policy needs them)
data "aws_caller_identity" "current" {
  count = local.create_dnssec_kms_key ? 1 : 0
}

data "aws_partition" "current" {
  count = local.create_dnssec_kms_key ? 1 : 0
}
