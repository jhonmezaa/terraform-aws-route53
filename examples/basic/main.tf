# =============================================================================
# Basic Example - Public Hosted Zone with Simple Records
# =============================================================================

module "route53" {
  source = "../../route53"

  account_name = var.account_name
  project_name = var.project_name

  # Create a public hosted zone
  zones = {
    main = {
      domain_name = var.domain_name
      comment     = "Public zone for ${var.project_name}"
    }
  }

  # Create DNS records
  records = {
    # Simple A record
    www = {
      zone_key = "main"
      name     = "www.${var.domain_name}"
      type     = "A"
      ttl      = 300
      records  = ["203.0.113.1"]
    }

    # CNAME record
    blog = {
      zone_key = "main"
      name     = "blog.${var.domain_name}"
      type     = "CNAME"
      ttl      = 300
      records  = ["www.${var.domain_name}"]
    }

    # MX records for email
    mail = {
      zone_key  = "main"
      full_name = var.domain_name
      type      = "MX"
      ttl       = 3600
      records = [
        "1 aspmx.l.google.com",
        "5 alt1.aspmx.l.google.com",
        "5 alt2.aspmx.l.google.com",
      ]
    }

    # TXT record for SPF
    spf = {
      zone_key  = "main"
      full_name = var.domain_name
      type      = "TXT"
      ttl       = 300
      records   = ["v=spf1 include:_spf.google.com ~all"]
    }
  }

  tags = {
    Environment = "production"
    Example     = "basic"
  }
}
