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
  description = "Domain name of the public hosted zone signed with DNSSEC."
  type        = string
}

variable "vpc_id" {
  description = "VPC for the resolver endpoint security group and the DNS Firewall association."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets (at least two, in different AZs) for the resolver endpoint."
  type        = list(string)
}

variable "onprem_cidr" {
  description = "CIDR allowed to query the inbound resolver endpoint on port 53."
  type        = string
  default     = "192.168.0.0/16"
}
