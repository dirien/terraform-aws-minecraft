mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = { partition = "aws", id = "aws" }
  }
  mock_data "aws_subnet" {
    defaults = { vpc_id = "vpc-0123456789abcdef0", availability_zone = "eu-central-1a" }
  }
  mock_data "aws_ami" {
    defaults = { id = "ami-0123456789abcdef0" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
}

variables {
  name          = "mc-test"
  subnet_id     = "subnet-0123456789abcdef0"
  server_url    = "https://example.com/server.jar"
  eula_accepted = true
}

run "rejects_invalid_minecraft_port" {
  command = plan

  variables {
    minecraft_port = 99999
  }

  expect_failures = [
    var.minecraft_port,
  ]
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    ssh_enabled       = true
    allowed_ssh_cidrs = ["not-a-cidr"]
  }

  expect_failures = [
    var.allowed_ssh_cidrs,
  ]
}

run "rejects_unaccepted_eula" {
  command = plan

  variables {
    eula_accepted = false
  }

  expect_failures = [
    aws_instance.this,
  ]
}

run "rejects_ssh_enabled_without_cidrs" {
  command = plan

  variables {
    ssh_enabled       = true
    allowed_ssh_cidrs = []
  }

  expect_failures = [
    aws_instance.this,
  ]
}

run "rejects_invalid_architecture" {
  command = plan

  variables {
    architecture = "ppc64"
  }

  expect_failures = [
    var.architecture,
  ]
}
