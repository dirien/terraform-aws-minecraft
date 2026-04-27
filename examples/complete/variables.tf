variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-central-1"
}

variable "subnet_id" {
  description = "Subnet ID where the Minecraft instance is launched."
  type        = string
}

variable "server_url" {
  description = "Minecraft server.jar URL."
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access."
  type        = string
}

variable "my_ip_cidr" {
  description = "Your IP in CIDR form (e.g. 203.0.113.1/32) for SSH ingress."
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for the DNS record."
  type        = string
}

variable "route53_record_name" {
  description = "FQDN to create (e.g. mc.example.com)."
  type        = string
}
