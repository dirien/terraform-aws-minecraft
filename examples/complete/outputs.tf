output "instance_id" {
  description = "EC2 instance ID."
  value       = module.minecraft.instance_id
}

output "eip_address" {
  description = "Elastic IP attached to the instance."
  value       = module.minecraft.eip_address
}

output "fqdn" {
  description = "Route 53 FQDN players connect to."
  value       = module.minecraft.route53_record_fqdn
}
