mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = { partition = "aws", id = "aws" }
  }
  mock_data "aws_subnet" {
    defaults = {
      vpc_id            = "vpc-0123456789abcdef0"
      availability_zone = "eu-central-1a"
    }
  }
  mock_data "aws_ami" {
    defaults = { id = "ami-0123456789abcdef0", architecture = "arm64" }
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

run "ssh_enabled_creates_rules" {
  command = plan

  variables {
    ssh_enabled       = true
    allowed_ssh_cidrs = ["203.0.113.1/32", "198.51.100.0/24"]
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.ssh) == 2
    error_message = "Expected one SSH rule per allowed CIDR."
  }
}

run "persistent_storage_creates_volume_and_attachment" {
  command = plan

  variables {
    persistent_storage_enabled = true
    data_volume_size           = 50
  }

  assert {
    condition     = length(aws_ebs_volume.data) == 1
    error_message = "Persistent storage should create one EBS volume."
  }

  assert {
    condition     = aws_ebs_volume.data[0].encrypted == true
    error_message = "Persistent EBS volume must be encrypted."
  }

  assert {
    condition     = length(aws_volume_attachment.data) == 1
    error_message = "Persistent storage should create one volume attachment."
  }
}

run "eip_enabled_allocates_address" {
  command = plan

  variables {
    eip_enabled = true
  }

  assert {
    condition     = length(aws_eip.this) == 1
    error_message = "EIP should be allocated when eip_enabled = true."
  }

  assert {
    condition     = aws_eip.this[0].domain == "vpc"
    error_message = "EIP domain must be vpc."
  }
}

run "tags_are_merged" {
  command = plan

  variables {
    tags = {
      Environment = "prod"
      Owner       = "platform"
    }
  }

  assert {
    condition     = aws_instance.this.tags["Environment"] == "prod"
    error_message = "Custom tags must be merged into the instance."
  }

  assert {
    condition     = aws_instance.this.tags["ManagedBy"] == "Terraform"
    error_message = "Module default tags must still be applied."
  }
}
