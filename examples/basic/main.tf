data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "minecraft" {
  source = "../../"

  name          = "mc-basic"
  subnet_id     = data.aws_subnets.default.ids[0]
  server_url    = var.server_url
  eula_accepted = true
}
