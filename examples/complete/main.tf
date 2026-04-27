module "minecraft" {
  source = "../../"

  name          = "mc-complete"
  subnet_id     = var.subnet_id
  instance_type = "t4g.medium"
  architecture  = "arm64"

  server_url      = var.server_url
  eula_accepted   = true
  java_min_memory = 2048
  java_max_memory = 3072

  ssh_enabled             = true
  allowed_ssh_cidrs       = [var.my_ip_cidr]
  allowed_minecraft_cidrs = ["0.0.0.0/0"]
  key_pair_name           = var.key_pair_name

  persistent_storage_enabled = true
  data_volume_size           = 50

  eip_enabled         = true
  route53_zone_id     = var.route53_zone_id
  route53_record_name = var.route53_record_name

  detailed_monitoring = true

  tags = {
    Environment = "prod"
    Owner       = "platform"
  }
}
