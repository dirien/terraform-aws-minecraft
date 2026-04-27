# terraform-aws-minecraft

[![Terraform Registry](https://img.shields.io/badge/registry-kn--lim%2Fminecraft%2Faws-623CE4?logo=terraform)](https://registry.terraform.io/modules/kn-lim/minecraft/aws/latest)
[![CI](https://github.com/kn-lim/terraform-aws-minecraft/actions/workflows/ci.yml/badge.svg)](https://github.com/kn-lim/terraform-aws-minecraft/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Run a self-hosted Minecraft server on AWS EC2 with sane, secure defaults:
encrypted EBS, IMDSv2-only, SSM Session Manager (no inbound SSH required),
optional persistent world storage, Elastic IP, and Route 53 DNS.

## Features

- Amazon Linux 2023 AMI lookup (x86_64 or arm64 / Graviton)
- Amazon Corretto 21 (required for Minecraft 1.20.5+)
- IMDSv2 enforced, EBS root encrypted by default
- IAM role + instance profile with `AmazonSSMManagedInstanceCore` so you can
  shell in via `aws ssm start-session` -- no SSH key or open port 22 needed
- Modern dedicated `aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule`
  resources (no legacy inline rules)
- Optional dedicated EBS volume mounted at `/opt/minecraft` so the world
  survives instance replacement
- Optional Elastic IP and Route 53 A record for a stable public address
- systemd unit so the server auto-restarts on crash and on reboot
- `terraform test` suite using `mock_provider`
- `moved {}` blocks for safe upgrade from v1

## Quick start

```hcl
module "minecraft" {
  source  = "kn-lim/minecraft/aws"
  version = "~> 1.0"

  name          = "mc"
  subnet_id     = "subnet-0123456789abcdef0"
  server_url    = "https://piston-data.mojang.com/v1/objects/.../server.jar"
  eula_accepted = true
}

output "address" {
  value = module.minecraft.instance_public_ip
}
```

Then connect to `<output address>:25565`. To shell into the box:

```bash
aws ssm start-session --target $(terraform output -raw instance_id)
```

See [`examples/basic`](examples/basic) and [`examples/complete`](examples/complete)
for complete, runnable configurations.

## Requirements

- Terraform >= 1.9
- AWS provider >= 5.0, < 7.0
- An existing VPC with at least one subnet (the module does not create a VPC)
- You must accept the [Minecraft EULA](https://aka.ms/MinecraftEULA) by setting
  `eula_accepted = true`

## Upgrading from v1.x

Variables `region`, `personal_ip`, and `personal_subnet` are removed; resource
addresses changed; the module no longer declares its own `provider "aws"`. See
[`docs/UPGRADING.md`](docs/UPGRADING.md) for a complete migration guide.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Run `terraform fmt -recursive`,
`terraform test`, and `tflint --recursive` before opening a PR.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0, < 7.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ebs_volume.data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_eip.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_volume_attachment.data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_vpc_security_group_egress_rule.all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.minecraft](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_ami.amazon_linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_subnet.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_server_url"></a> [server\_url](#input\_server\_url) | URL of the Minecraft server.jar to install on first boot. | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | ID of the subnet where the EC2 instance is launched. | `string` | n/a | yes |
| <a name="input_allowed_minecraft_cidrs"></a> [allowed\_minecraft\_cidrs](#input\_allowed\_minecraft\_cidrs) | CIDR blocks allowed to reach the Minecraft TCP port. | `list(string)` | `["0.0.0.0/0"]` | no |
| <a name="input_allowed_ssh_cidrs"></a> [allowed\_ssh\_cidrs](#input\_allowed\_ssh\_cidrs) | CIDR blocks allowed to reach SSH. Required when ssh\_enabled = true. | `list(string)` | `[]` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | Override AMI ID. | `string` | `null` | no |
| <a name="input_architecture"></a> [architecture](#input\_architecture) | CPU architecture for the default AMI lookup. | `string` | `"x86_64"` | no |
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | Assign a public IP. | `bool` | `true` | no |
| <a name="input_create_iam_role"></a> [create\_iam\_role](#input\_create\_iam\_role) | Create an IAM role and instance profile. | `bool` | `true` | no |
| <a name="input_data_volume_size"></a> [data\_volume\_size](#input\_data\_volume\_size) | Size in GiB of the persistent data volume. | `number` | `20` | no |
| <a name="input_data_volume_type"></a> [data\_volume\_type](#input\_data\_volume\_type) | Type of the persistent data volume. | `string` | `"gp3"` | no |
| <a name="input_detailed_monitoring"></a> [detailed\_monitoring](#input\_detailed\_monitoring) | Enable EC2 detailed CloudWatch monitoring. | `bool` | `false` | no |
| <a name="input_eip_enabled"></a> [eip\_enabled](#input\_eip\_enabled) | Allocate an Elastic IP. | `bool` | `false` | no |
| <a name="input_eula_accepted"></a> [eula\_accepted](#input\_eula\_accepted) | Set to true to accept the Minecraft EULA. | `bool` | `false` | no |
| <a name="input_iam_instance_profile_name"></a> [iam\_instance\_profile\_name](#input\_iam\_instance\_profile\_name) | Pre-existing IAM instance profile name. | `string` | `null` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type. | `string` | `"t3.small"` | no |
| <a name="input_java_max_memory"></a> [java\_max\_memory](#input\_java\_max\_memory) | Maximum heap size in MB for the JVM (-Xmx). | `number` | `1024` | no |
| <a name="input_java_min_memory"></a> [java\_min\_memory](#input\_java\_min\_memory) | Initial heap size in MB for the JVM (-Xms). | `number` | `1024` | no |
| <a name="input_key_pair_name"></a> [key\_pair\_name](#input\_key\_pair\_name) | Optional EC2 key pair name. | `string` | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Customer-managed KMS key ARN for EBS encryption. | `string` | `null` | no |
| <a name="input_minecraft_port"></a> [minecraft\_port](#input\_minecraft\_port) | TCP port the Minecraft server listens on. | `number` | `25565` | no |
| <a name="input_name"></a> [name](#input\_name) | Base name used for all resources created by this module. | `string` | `"minecraft"` | no |
| <a name="input_persistent_storage_enabled"></a> [persistent\_storage\_enabled](#input\_persistent\_storage\_enabled) | Attach a separate EBS volume mounted at /opt/minecraft. | `bool` | `false` | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | Size in GiB of the EBS root volume. | `number` | `20` | no |
| <a name="input_root_volume_type"></a> [root\_volume\_type](#input\_root\_volume\_type) | Type of the EBS root volume. | `string` | `"gp3"` | no |
| <a name="input_route53_record_name"></a> [route53\_record\_name](#input\_route53\_record\_name) | FQDN to create. | `string` | `null` | no |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | Route 53 hosted zone ID. | `string` | `null` | no |
| <a name="input_ssh_enabled"></a> [ssh\_enabled](#input\_ssh\_enabled) | Open TCP/22 to allowed\_ssh\_cidrs. | `bool` | `false` | no |
| <a name="input_ssm_enabled"></a> [ssm\_enabled](#input\_ssm\_enabled) | Attach AmazonSSMManagedInstanceCore. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags merged into every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ami_id"></a> [ami\_id](#output\_ami\_id) | AMI ID used for the instance. |
| <a name="output_data_volume_id"></a> [data\_volume\_id](#output\_data\_volume\_id) | ID of the persistent data EBS volume, if created. |
| <a name="output_eip_address"></a> [eip\_address](#output\_eip\_address) | Elastic IP address, if allocated. |
| <a name="output_iam_instance_profile_arn"></a> [iam\_instance\_profile\_arn](#output\_iam\_instance\_profile\_arn) | IAM instance profile ARN, if created. |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | IAM role ARN attached to the instance, if created. |
| <a name="output_instance_arn"></a> [instance\_arn](#output\_instance\_arn) | EC2 instance ARN. |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | EC2 instance ID. |
| <a name="output_instance_private_ip"></a> [instance\_private\_ip](#output\_instance\_private\_ip) | Private IP address. |
| <a name="output_instance_public_dns"></a> [instance\_public\_dns](#output\_instance\_public\_dns) | Public DNS name of the instance. |
| <a name="output_instance_public_ip"></a> [instance\_public\_ip](#output\_instance\_public\_ip) | Public IP address. |
| <a name="output_route53_record_fqdn"></a> [route53\_record\_fqdn](#output\_route53\_record\_fqdn) | FQDN of the created Route 53 record, if any. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security group ID. |
| <a name="output_ssm_connect_command"></a> [ssm\_connect\_command](#output\_ssm\_connect\_command) | AWS CLI command to start an SSM Session Manager shell on the instance. |
<!-- END_TF_DOCS -->

## License

[MIT](LICENSE)
