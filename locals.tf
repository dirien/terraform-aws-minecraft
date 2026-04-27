locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux[0].id

  default_tags = {
    Name      = var.name
    ManagedBy = "Terraform"
    Module    = "terraform-aws-minecraft"
  }

  tags = merge(local.default_tags, var.tags)

  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    server_url         = var.server_url
    java_major_version = var.java_major_version
    java_min_memory    = var.java_min_memory
    java_max_memory    = var.java_max_memory
    minecraft_port     = var.minecraft_port
    eula_accepted      = var.eula_accepted
    persist_data       = var.persistent_storage_enabled
  })
}
