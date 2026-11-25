# =============================================================================
# DNSSEC + Resolver DNS Firewall + Resolver endpoint security group
# =============================================================================

module "route53" {
  source = "../../route53"

  account_name = var.account_name
  project_name = var.project_name

  tags_common = {
    Environment = var.account_name
  }

  # ===========================================================================
  # DNSSEC: public zone signed with a KMS key created by the module (us-east-1)
  # ===========================================================================

  zones = {
    public = {
      domain_name   = var.domain_name
      enable_dnssec = true
    }
  }

  dnssec_kms_key_aliases = ["${var.account_name}-${var.project_name}-dnssec"]

  # ===========================================================================
  # Resolver inbound endpoint with a security group created by the module
  # ===========================================================================

  resolver_endpoints = {
    inbound = {
      direction             = "INBOUND"
      create_security_group = true
      vpc_id                = var.vpc_id
      ip_addresses          = [for subnet_id in var.subnet_ids : { subnet_id = subnet_id }]

      security_group_ingress_rules = {
        onprem = {
          description = "DNS from on-premises"
          cidr_ipv4   = var.onprem_cidr
        }
      }
    }
  }

  # ===========================================================================
  # DNS Firewall
  # ===========================================================================

  firewall_domain_lists = {
    blocked = {
      domains = ["malware.example.", "*.phishing.example."]
    }
  }

  firewall_rule_groups = {
    main = {
      rules = {
        allow-corp = {
          priority = 100
          action   = "ALLOW"
          domains  = ["corp.${var.domain_name}."]
        }
        block-bad = {
          priority        = 200
          action          = "BLOCK"
          block_response  = "NXDOMAIN"
          domain_list_key = "blocked"
        }
      }

      vpc_associations = {
        app = {
          vpc_id   = var.vpc_id
          priority = 101
        }
      }
    }
  }
}
