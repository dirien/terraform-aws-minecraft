data "aws_partition" "current" {}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

data "aws_ami" "amazon_linux" {
  count = var.ami_id == null ? 1 : 0

  owners      = ["amazon"]
  most_recent = true

  filter {
    name = "name"
    values = [
      var.architecture == "arm64" ? "al2023-ami-2023.*-arm64" : "al2023-ami-2023.*-x86_64",
    ]
  }

  filter {
    name   = "architecture"
    values = [var.architecture]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
