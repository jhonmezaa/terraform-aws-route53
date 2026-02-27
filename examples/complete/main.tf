# =============================================================================
# Complete Example - All Route53 Features
# =============================================================================

module "route53" {
  source = "../../route53"

  account_name = var.account_name
  project_name = var.project_name

  # ===========================================================================
  # Delegation Sets
  # ===========================================================================

  delegation_sets = {
    main = {
      reference_name = "main-delegation"
    }
  }

  # ===========================================================================
  # Hosted Zones
  # ===========================================================================

  zones = {
    # Public hosted zone
    public = {
      domain_name   = var.domain_name
      comment       = "Public zone for ${var.project_name}"
      force_destroy = true
      tags = {
        Type = "public"
      }
    }

    # Private hosted zone
    private = {
      domain_name = var.private_domain_name
      comment     = "Private zone for ${var.project_name}"
      vpc = [
        {
          vpc_id     = var.vpc_id
          vpc_region = var.aws_region
        }
      ]
      tags = {
        Type = "private"
      }
    }
  }

  # ===========================================================================
  # DNS Records
  # ===========================================================================

  records = {
    # Simple A record
    www = {
      zone_key = "public"
      name     = "www.${var.domain_name}"
      type     = "A"
      ttl      = 300
      records  = ["203.0.113.1"]
    }

    # Alias record pointing to ALB
    app = {
      zone_key = "public"
      name     = "app.${var.domain_name}"
      type     = "A"
      alias = {
        name                   = var.alb_dns_name
        zone_id                = var.alb_zone_id
        evaluate_target_health = true
      }
    }

    # AAAA alias record for the same ALB (IPv6)
    app-ipv6 = {
      zone_key = "public"
      name     = "app.${var.domain_name}"
      type     = "AAAA"
      alias = {
        name                   = var.alb_dns_name
        zone_id                = var.alb_zone_id
        evaluate_target_health = true
      }
    }

    # MX records for email
    mail = {
      zone_key  = "public"
      full_name = var.domain_name
      type      = "MX"
      ttl       = 3600
      records = [
        "1 aspmx.l.google.com",
        "5 alt1.aspmx.l.google.com",
        "5 alt2.aspmx.l.google.com",
        "10 alt3.aspmx.l.google.com",
        "10 alt4.aspmx.l.google.com",
      ]
    }

    # TXT record for SPF
    spf = {
      zone_key  = "public"
      full_name = var.domain_name
      type      = "TXT"
      ttl       = 300
      records   = ["v=spf1 include:_spf.google.com ~all"]
    }

    # CAA record
    caa = {
      zone_key  = "public"
      full_name = var.domain_name
      type      = "CAA"
      ttl       = 3600
      records = [
        "0 issue \"amazon.com\"",
        "0 issue \"letsencrypt.org\"",
      ]
    }

    # Weighted routing - blue/green
    blue = {
      zone_key       = "public"
      name           = "weighted.${var.domain_name}"
      type           = "CNAME"
      ttl            = 60
      records        = ["blue.${var.domain_name}"]
      set_identifier = "blue"
      weighted_routing_policy = {
        weight = 90
      }
    }

    green = {
      zone_key       = "public"
      name           = "weighted.${var.domain_name}"
      type           = "CNAME"
      ttl            = 60
      records        = ["green.${var.domain_name}"]
      set_identifier = "green"
      weighted_routing_policy = {
        weight = 10
      }
    }

    # Geolocation routing
    geo-eu = {
      zone_key       = "public"
      name           = "geo.${var.domain_name}"
      type           = "CNAME"
      ttl            = 60
      records        = ["eu.${var.domain_name}"]
      set_identifier = "europe"
      geolocation_routing_policy = {
        continent = "EU"
      }
    }

    geo-default = {
      zone_key       = "public"
      name           = "geo.${var.domain_name}"
      type           = "CNAME"
      ttl            = 60
      records        = ["us.${var.domain_name}"]
      set_identifier = "default"
      geolocation_routing_policy = {
        country = "*"
      }
    }

    # Latency-based routing
    latency-us = {
      zone_key       = "public"
      name           = "latency.${var.domain_name}"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.1"]
      set_identifier = "us-east-1"
      latency_routing_policy = {
        region = "us-east-1"
      }
    }

    latency-eu = {
      zone_key       = "public"
      name           = "latency.${var.domain_name}"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.2"]
      set_identifier = "eu-west-1"
      latency_routing_policy = {
        region = "eu-west-1"
      }
    }

    # Failover routing with health check reference
    failover-primary = {
      zone_key         = "public"
      name             = "failover.${var.domain_name}"
      type             = "A"
      ttl              = 60
      records          = ["203.0.113.1"]
      set_identifier   = "primary"
      health_check_key = "primary-web"
      failover_routing_policy = {
        type = "PRIMARY"
      }
    }

    failover-secondary = {
      zone_key       = "public"
      name           = "failover.${var.domain_name}"
      type           = "A"
      ttl            = 60
      records        = ["203.0.113.2"]
      set_identifier = "secondary"
      failover_routing_policy = {
        type = "SECONDARY"
      }
    }

    # Private zone record
    internal-api = {
      zone_key = "private"
      name     = "api.${var.private_domain_name}"
      type     = "A"
      ttl      = 300
      records  = ["10.0.1.100"]
    }

    internal-db = {
      zone_key = "private"
      name     = "db.${var.private_domain_name}"
      type     = "CNAME"
      ttl      = 300
      records  = ["my-rds-instance.abcdef123456.us-east-1.rds.amazonaws.com"]
    }
  }

  # ===========================================================================
  # Health Checks
  # ===========================================================================

  health_checks = {
    # HTTP health check
    primary-web = {
      type              = "HTTPS"
      fqdn              = "app.${var.domain_name}"
      port              = 443
      resource_path     = "/health"
      failure_threshold = 3
      request_interval  = 30
      measure_latency   = true
      tags = {
        Purpose = "failover-primary"
      }
    }

    # TCP health check
    tcp-check = {
      type              = "TCP"
      fqdn              = "api.${var.domain_name}"
      port              = 443
      failure_threshold = 3
      request_interval  = 30
    }

    # Calculated health check (composite of child checks)
    composite = {
      type                   = "CALCULATED"
      child_health_threshold = 1
      tags = {
        Purpose = "composite-check"
      }
    }
  }

  tags = {
    Environment = "production"
    Example     = "complete"
  }
}
