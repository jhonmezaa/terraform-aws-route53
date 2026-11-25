# =============================================================================
# DNSSEC (public hosted zones)
# =============================================================================

locals {
  dnssec_zones = { for k, v in var.zones : k => v if var.create && v.enable_dnssec }

  # One KMS key (us-east-1, ECC_NIST_P256, SIGN_VERIFY) is shared by every zone that
  # enables DNSSEC and does not bring its own key (zones.dnssec_kms_key_arn or var.dnssec_kms_key_arn)
  create_dnssec_kms_key = var.create && var.create_dnssec_kms_key && var.dnssec_kms_key_arn == null && length([
    for k, v in local.dnssec_zones : k if v.dnssec_kms_key_arn == null
  ]) > 0

  dnssec_kms_key_name = "${local.name_prefix}kms-dnssec-${var.account_name}-${var.project_name}"

  dnssec_kms_key_arns = {
    for k, v in local.dnssec_zones : k => try(coalesce(
      v.dnssec_kms_key_arn,
      var.dnssec_kms_key_arn,
      try(aws_kms_key.dnssec[0].arn, null)
    ), null)
  }

  # KSK names only allow letters, numbers and underscores (3-128 characters)
  dnssec_key_signing_key_names = {
    for k, v in local.dnssec_zones : k => coalesce(
      v.dnssec_key_signing_key_name,
      substr("ksk_${replace(trimsuffix(v.domain_name, "."), "/[^0-9A-Za-z_]/", "_")}", 0, 128)
    )
  }
}

data "aws_iam_policy_document" "dnssec_kms" {
  count = local.create_dnssec_kms_key ? 1 : 0

  statement {
    sid       = "EnableIAMUserPermissions"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current[0].partition}:iam::${data.aws_caller_identity.current[0].account_id}:root"]
    }
  }

  statement {
    sid       = "AllowRoute53DNSSECService"
    actions   = ["kms:DescribeKey", "kms:GetPublicKey", "kms:Sign"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["dnssec-route53.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current[0].account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current[0].partition}:route53:::hostedzone/*"]
    }
  }

  statement {
    sid       = "AllowRoute53DNSSECToCreateGrant"
    actions   = ["kms:CreateGrant"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["dnssec-route53.amazonaws.com"]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current[0].account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current[0].partition}:route53:::hostedzone/*"]
    }
  }
}

resource "aws_kms_key" "dnssec" {
  count = local.create_dnssec_kms_key ? 1 : 0

  # Route53 DNSSEC requires the KMS key to live in us-east-1
  region = "us-east-1"

  description              = var.dnssec_kms_key_description
  key_usage                = "SIGN_VERIFY"
  customer_master_key_spec = "ECC_NIST_P256"
  enable_key_rotation      = false
  deletion_window_in_days  = var.dnssec_kms_key_deletion_window_in_days
  policy                   = data.aws_iam_policy_document.dnssec_kms[0].json

  tags = merge(
    local.common_tags,
    var.dnssec_kms_key_tags,
    {
      Name      = local.dnssec_kms_key_name
      ManagedBy = "Terraform"
    }
  )
}

resource "aws_kms_alias" "dnssec" {
  for_each = toset(local.create_dnssec_kms_key ? var.dnssec_kms_key_aliases : [])

  region = "us-east-1"

  name          = startswith(each.value, "alias/") ? each.value : "alias/${each.value}"
  target_key_id = aws_kms_key.dnssec[0].key_id
}

resource "aws_route53_key_signing_key" "this" {
  for_each = local.dnssec_zones

  name                       = local.dnssec_key_signing_key_names[each.key]
  hosted_zone_id             = local.zone_id_map[each.key]
  key_management_service_arn = local.dnssec_kms_key_arns[each.key]
  status                     = each.value.dnssec_key_signing_key_status

  lifecycle {
    precondition {
      condition     = length(each.value.vpc) == 0
      error_message = "DNSSEC solo se puede habilitar en zonas públicas (la zona \"${each.key}\" tiene VPC asociadas)."
    }

    precondition {
      condition     = local.dnssec_kms_key_arns[each.key] != null
      error_message = "La zona \"${each.key}\" habilita DNSSEC sin clave KMS: define zones.dnssec_kms_key_arn, dnssec_kms_key_arn o create_dnssec_kms_key = true."
    }
  }
}

resource "aws_route53_hosted_zone_dnssec" "this" {
  for_each = local.dnssec_zones

  hosted_zone_id = aws_route53_key_signing_key.this[each.key].hosted_zone_id
  signing_status = each.value.dnssec_signing_status
}
