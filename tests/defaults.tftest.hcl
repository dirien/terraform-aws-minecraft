###############################################################################
# Plan-only tests using mocked AWS provider. No real AWS API calls.
###############################################################################

mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
      id        = "aws"
    }
  }

  mock_data "aws_subnet" {
    defaults = {
      vpc_id            = "vpc-0123456789abcdef0"
      availability_zone = "eu-central-1a"
      cidr_block        = "10.0.0.0/24"
    }
  }

  mock_data "aws_ami" {
    defaults = {
      id           = "ami-0123456789abcdef0"
      architecture = "x86_64"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

variables {
  name          = "mc-test"
  subnet_id     = "subnet-0123456789abcdef0"
  server_url    = "https://example.com/server.jar"
  eula_accepted = true
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = aws_instance.this.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be required."
  }

  assert {
    condition     = aws_instance.this.root_block_device[0].encrypted == true
    error_message = "Root EBS volume must be encrypted by default."
  }

  assert {
    condition     = aws_instance.this.ebs_optimized == true
    error_message = "Instance must be EBS-optimized."
  }

  assert {
    condition     = aws_instance.this.user_data_replace_on_change == true
    error_message = "user_data changes must trigger instance replacement."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.ssh) == 0
    error_message = "SSH must be closed by default."
  }

  assert {
    condition     = length(aws_iam_role.this) == 1
    error_message = "IAM role for SSM should be created by default."
  }
}

run "minecraft_rule_open_to_world_by_default" {
  command = plan

  assert {
    condition     = contains([for r in aws_vpc_security_group_ingress_rule.minecraft : r.cidr_ipv4], "0.0.0.0/0")
    error_message = "Default Minecraft ingress should be 0.0.0.0/0."
  }

  assert {
    condition     = [for r in aws_vpc_security_group_ingress_rule.minecraft : r.from_port][0] == 25565
    error_message = "Default Minecraft port should be 25565."
  }
}

run "no_persistent_storage_by_default" {
  command = plan

  assert {
    condition     = length(aws_ebs_volume.data) == 0
    error_message = "Persistent EBS volume should be opt-in."
  }

  assert {
    condition     = length(aws_eip.this) == 0
    error_message = "Elastic IP should be opt-in."
  }
}
