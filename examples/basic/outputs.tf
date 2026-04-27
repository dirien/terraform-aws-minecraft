output "instance_public_ip" {
  description = "Public IP of the Minecraft server."
  value       = module.minecraft.instance_public_ip
}

output "ssm_connect_command" {
  description = "Command to open an SSM shell on the instance."
  value       = module.minecraft.ssm_connect_command
}
