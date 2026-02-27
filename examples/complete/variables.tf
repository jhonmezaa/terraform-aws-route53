variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
  default     = "us-east-1"
}

variable "account_name" {
  description = "Account name for resource naming."
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming."
  type        = string
}

variable "domain_name" {
  description = "Domain name for the public hosted zone."
  type        = string
}

variable "private_domain_name" {
  description = "Domain name for the private hosted zone."
  type        = string
  default     = "internal.example.com"
}

variable "vpc_id" {
  description = "VPC ID for private hosted zone."
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB for alias record."
  type        = string
  default     = "my-alb-123456.us-east-1.elb.amazonaws.com"
}

variable "alb_zone_id" {
  description = "Zone ID of the ALB for alias record."
  type        = string
  default     = "Z35SXDOTRQ7X7K"
}
