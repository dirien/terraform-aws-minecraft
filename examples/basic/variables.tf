variable "region" {
  description = "AWS region."
  type        = string
  default     = "eu-central-1"
}

variable "server_url" {
  description = "Minecraft server.jar URL. See https://www.minecraft.net/en-us/download/server."
  type        = string
}
