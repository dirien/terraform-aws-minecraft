# Changelog

All notable changes to this project will be documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0](https://github.com/dirien/terraform-aws-minecraft/compare/v0.1.0...v1.0.0) (2026-04-27)


### ⚠ BREAKING CHANGES

* provider block removed from module; region, personal_ip, personal_subnet variables removed; subnet_id and eula_accepted now required; resource addresses changed (moved blocks ship the rename for state).

### Features

* v2 module rewrite with secure defaults, examples, tests, CI ([3136ffa](https://github.com/dirien/terraform-aws-minecraft/commit/3136ffa5b1cdbe116560e67a241559a7c10e43d8))

## [Unreleased]

### Breaking changes

- Removed the `provider "aws"` block from the module. The consumer must now
  configure the AWS provider in the root module.
- Removed `region`, `personal_ip`, and `personal_subnet` variables.
- Renamed `aws_instance.minecraft_instance` to `aws_instance.this`. A `moved {}`
  block keeps existing state in place.
- Renamed `aws_security_group.minecraft_sg` to `aws_security_group.this`. A
  `moved {}` block keeps existing state in place.
- Replaced inline `ingress`/`egress` blocks with dedicated
  `aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule`
  resources. State will need refreshing.
- Switched from `security_groups` (name-based) to `vpc_security_group_ids`.
- `subnet_id` is now required (no default VPC fallback).
- `eula_accepted = true` is required for the instance to start.

### Added

- IMDSv2 enforcement (`http_tokens = "required"`).
- Encrypted EBS root volume (`gp3`, customer KMS key optional).
- IAM role + instance profile with `AmazonSSMManagedInstanceCore` for SSM
  Session Manager access.
- Optional persistent EBS data volume mounted at `/opt/minecraft`.
- Optional Elastic IP and Route 53 A record.
- Graviton/arm64 support via `architecture` variable.
- systemd unit `minecraft.service` for auto-restart.
- Variable validation for CIDRs, ports, sizes, naming.
- `moved {}` blocks for v1 -> v2 upgrade.
- `examples/basic` and `examples/complete`.
- `tests/*.tftest.hcl` plan-only tests using `mock_provider`.
- GitHub Actions CI: fmt, validate (matrix), test, tflint, trivy, terraform-docs.
- Dependabot for terraform + actions.
- pre-commit-terraform hooks.
- `terraform-docs` README injection.

### Changed

- Default instance type bumped from `t2.small` to `t3.small`.
- Provider version constraint from `5.97.0` (pinned) to `>= 5.0, < 7.0`.
- Required Terraform version bumped to `>= 1.9` (cross-variable validation,
  mock providers).
- AMI lookup now filters by architecture.
- User data switched to `templatefile()` and a systemd-managed Minecraft
  service. `user_data_replace_on_change = true`.

## [1.0.0] - prior

Original module by `kn-lim`.
