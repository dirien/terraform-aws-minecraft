###############################################################################
# Identity & placement
###############################################################################

variable "name" {
  description = "Base name used for all resources created by this module."
  type        = string
  default     = "minecraft"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,31}$", var.name))
    error_message = "name must be 1-32 chars: lowercase letters, digits, or hyphens; must start with a letter or digit."
  }
}

variable "subnet_id" {
  description = "ID of the subnet where the EC2 instance is launched. Determines the VPC and availability zone."
  type        = string

  validation {
    condition     = can(regex("^subnet-[0-9a-f]{8,17}$", var.subnet_id))
    error_message = "subnet_id must be a valid subnet ID (e.g. subnet-0123456789abcdef0)."
  }
}

variable "tags" {
  description = "Additional tags merged into every resource created by this module."
  type        = map(string)
  default     = {}
}

###############################################################################
# Compute
###############################################################################

variable "instance_type" {
  description = "EC2 instance type. Defaults to t3.small (x86_64). Use a t4g/c7g/m7g family with architecture = arm64 for Graviton."
  type        = string
  default     = "t3.small"
}

variable "architecture" {
  description = "CPU architecture used to look up the default Amazon Linux 2023 AMI. Ignored when ami_id is set."
  type        = string
  default     = "x86_64"

  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "architecture must be x86_64 or arm64."
  }
}

variable "ami_id" {
  description = "Override AMI ID. When null (default) the module looks up the latest Amazon Linux 2023 AMI for the chosen architecture."
  type        = string
  default     = null
}

variable "key_pair_name" {
  description = "Optional EC2 key pair name. Leave null to rely on SSM Session Manager for shell access."
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Assign a public IP to the instance. Set to false when running in a private subnet behind NAT/VPN."
  type        = bool
  default     = true
}

variable "detailed_monitoring" {
  description = "Enable EC2 detailed (1-minute) CloudWatch monitoring."
  type        = bool
  default     = false
}

###############################################################################
# IAM / SSM
###############################################################################

variable "create_iam_role" {
  description = "Create an IAM role and instance profile for the EC2 instance."
  type        = bool
  default     = true
}

variable "ssm_enabled" {
  description = "Attach AmazonSSMManagedInstanceCore so the instance is reachable via SSM Session Manager."
  type        = bool
  default     = true
}

variable "iam_instance_profile_name" {
  description = "Pre-existing IAM instance profile name. Used only when create_iam_role = false."
  type        = string
  default     = null
}

###############################################################################
# Networking / firewall
###############################################################################

variable "ssh_enabled" {
  description = "Open TCP/22 to allowed_ssh_cidrs. Disabled by default - prefer SSM Session Manager."
  type        = bool
  default     = false
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to reach SSH. Required when ssh_enabled = true."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for c in var.allowed_ssh_cidrs : can(cidrnetmask(c))
    ])
    error_message = "All entries in allowed_ssh_cidrs must be valid CIDR notation."
  }
}

variable "allowed_minecraft_cidrs" {
  description = "CIDR blocks allowed to reach the Minecraft TCP port. Default opens to the public internet."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for c in var.allowed_minecraft_cidrs : can(cidrnetmask(c))
    ])
    error_message = "All entries in allowed_minecraft_cidrs must be valid CIDR notation."
  }
}

variable "minecraft_port" {
  description = "TCP port the Minecraft server listens on."
  type        = number
  default     = 25565

  validation {
    condition     = var.minecraft_port >= 1 && var.minecraft_port <= 65535
    error_message = "minecraft_port must be between 1 and 65535."
  }
}

###############################################################################
# Server bootstrap
###############################################################################

variable "server_url" {
  description = "URL of the Minecraft server.jar to install on first boot. See https://www.minecraft.net/en-us/download/server."
  type        = string

  validation {
    condition     = can(regex("^https?://", var.server_url))
    error_message = "server_url must be a valid http(s) URL."
  }
}

variable "java_major_version" {
  description = "Major version of Amazon Corretto to install. Minecraft 1.20.5+ needs 21; 1.21.9+ needs 25."
  type        = number
  default     = 25

  validation {
    condition     = contains([17, 21, 22, 23, 24, 25], var.java_major_version)
    error_message = "java_major_version must be one of: 17, 21, 22, 23, 24, 25 (matching Amazon Linux 2023 packages)."
  }
}

variable "java_min_memory" {
  description = "Initial heap size in MB for the JVM (-Xms)."
  type        = number
  default     = 1024

  validation {
    condition     = var.java_min_memory >= 512
    error_message = "java_min_memory must be >= 512 MB."
  }
}

variable "java_max_memory" {
  description = "Maximum heap size in MB for the JVM (-Xmx). Must be >= java_min_memory."
  type        = number
  default     = 1024

  validation {
    condition     = var.java_max_memory >= 512
    error_message = "java_max_memory must be >= 512 MB."
  }
}

variable "eula_accepted" {
  description = "Set to true to accept the Minecraft EULA (https://aka.ms/MinecraftEULA). The server will not start otherwise."
  type        = bool
  default     = false
}

###############################################################################
# Storage
###############################################################################

variable "root_volume_size" {
  description = "Size in GiB of the EBS root volume."
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "root_volume_size must be at least 8 GiB."
  }
}

variable "root_volume_type" {
  description = "Type of the EBS root volume."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.root_volume_type)
    error_message = "root_volume_type must be one of: gp3, gp2, io1, io2."
  }
}

variable "persistent_storage_enabled" {
  description = "Attach a separate EBS volume mounted at /opt/minecraft so the world survives instance replacement."
  type        = bool
  default     = false
}

variable "data_volume_size" {
  description = "Size in GiB of the persistent data volume."
  type        = number
  default     = 20
}

variable "data_volume_type" {
  description = "Type of the persistent data volume."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2", "st1", "sc1"], var.data_volume_type)
    error_message = "data_volume_type must be one of: gp3, gp2, io1, io2, st1, sc1."
  }
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN for EBS encryption. Defaults to the AWS-managed EBS key when null."
  type        = string
  default     = null
}

###############################################################################
# DNS / addressing
###############################################################################

variable "eip_enabled" {
  description = "Allocate an Elastic IP and attach it to the instance for a stable public address."
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID. When set, an A record is created for the instance."
  type        = string
  default     = null
}

variable "route53_record_name" {
  description = "FQDN to create in route53_zone_id. Required when route53_zone_id is set."
  type        = string
  default     = null
}
