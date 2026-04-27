###############################################################################
# Security group + rules
###############################################################################

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  description = "Security group for Minecraft server ${var.name}"
  vpc_id      = data.aws_subnet.selected.vpc_id

  tags = merge(local.tags, { Name = "${var.name}-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = var.ssh_enabled ? toset(var.allowed_ssh_cidrs) : toset([])

  security_group_id = aws_security_group.this.id
  description       = "SSH access"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value

  tags = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "minecraft" {
  for_each = toset(var.allowed_minecraft_cidrs)

  security_group_id = aws_security_group.this.id
  description       = "Minecraft TCP"
  ip_protocol       = "tcp"
  from_port         = var.minecraft_port
  to_port           = var.minecraft_port
  cidr_ipv4         = each.value

  tags = local.tags
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = local.tags
}

###############################################################################
# IAM role + instance profile (for SSM Session Manager)
###############################################################################

data "aws_iam_policy_document" "assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  count = var.create_iam_role ? 1 : 0

  name               = "${var.name}-role"
  description        = "IAM role for Minecraft EC2 instance ${var.name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.create_iam_role && var.ssm_enabled ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  count = var.create_iam_role ? 1 : 0

  name = "${var.name}-profile"
  role = aws_iam_role.this[0].name

  tags = local.tags
}

###############################################################################
# EC2 instance
###############################################################################

resource "aws_instance" "this" {
  ami           = local.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [aws_security_group.this.id]

  iam_instance_profile = (
    var.create_iam_role
    ? aws_iam_instance_profile.this[0].name
    : var.iam_instance_profile_name
  )

  user_data                   = local.user_data
  user_data_replace_on_change = true

  monitoring                           = var.detailed_monitoring
  associate_public_ip_address          = var.associate_public_ip_address
  instance_initiated_shutdown_behavior = "stop"
  ebs_optimized                        = true

  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted             = true
    kms_key_id            = var.kms_key_arn
    delete_on_termination = true
  }

  tags        = merge(local.tags, { Name = var.name })
  volume_tags = merge(local.tags, { Name = "${var.name}-root" })

  lifecycle {
    ignore_changes = [ami]

    precondition {
      condition     = var.eula_accepted
      error_message = "You must accept the Minecraft EULA (https://aka.ms/MinecraftEULA) by setting eula_accepted = true."
    }

    precondition {
      condition     = !var.ssh_enabled || length(var.allowed_ssh_cidrs) > 0
      error_message = "ssh_enabled = true requires at least one CIDR in allowed_ssh_cidrs."
    }

    precondition {
      condition     = var.create_iam_role || var.iam_instance_profile_name != null || !var.ssm_enabled
      error_message = "ssm_enabled requires either create_iam_role = true or a pre-existing iam_instance_profile_name."
    }
  }
}

###############################################################################
# Persistent EBS data volume (optional)
###############################################################################

resource "aws_ebs_volume" "data" {
  count = var.persistent_storage_enabled ? 1 : 0

  availability_zone = aws_instance.this.availability_zone
  size              = var.data_volume_size
  type              = var.data_volume_type
  encrypted         = true
  kms_key_id        = var.kms_key_arn

  tags = merge(local.tags, { Name = "${var.name}-data" })
}

resource "aws_volume_attachment" "data" {
  count = var.persistent_storage_enabled ? 1 : 0

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data[0].id
  instance_id = aws_instance.this.id
}

###############################################################################
# Optional Elastic IP
###############################################################################

resource "aws_eip" "this" {
  count = var.eip_enabled ? 1 : 0

  domain   = "vpc"
  instance = aws_instance.this.id

  tags = merge(local.tags, { Name = "${var.name}-eip" })
}

###############################################################################
# Optional Route 53 DNS record
###############################################################################

resource "aws_route53_record" "this" {
  count = var.route53_zone_id != null ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.route53_record_name
  type    = "A"
  ttl     = 300
  records = [
    var.eip_enabled ? aws_eip.this[0].public_ip : aws_instance.this.public_ip,
  ]

  lifecycle {
    precondition {
      condition     = var.route53_record_name != null
      error_message = "route53_record_name must be set when route53_zone_id is provided."
    }
  }
}

###############################################################################
# Backwards-compatibility moved blocks (v1 -> v2)
###############################################################################

moved {
  from = aws_instance.minecraft_instance
  to   = aws_instance.this
}

moved {
  from = aws_security_group.minecraft_sg
  to   = aws_security_group.this
}
