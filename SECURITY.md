# Security

## Reporting a vulnerability

Please do **not** open a public GitHub issue for security reports. Instead,
use [GitHub private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability)
on this repository, or email the maintainer listed on the registry page.

You should receive an acknowledgement within 5 business days.

## Defaults this module ships with

- IMDSv2 is required (`http_tokens = "required"`).
- Root EBS volume is encrypted; pass `kms_key_arn` to use a customer-managed key.
- Instance gets an IAM role with `AmazonSSMManagedInstanceCore` so you can
  shell in without exposing SSH.
- SSH ingress is **off** by default.
- Minecraft TCP port is open to `0.0.0.0/0` by default because that is the
  product's intended use; restrict it with `allowed_minecraft_cidrs`.

## Hardening checklist

- [ ] Restrict `allowed_minecraft_cidrs` if your server is private.
- [ ] Set `kms_key_arn` to a customer-managed CMK.
- [ ] Set `persistent_storage_enabled = true` so a compromised root disk can
      be replaced without losing the world.
- [ ] Use `architecture = "arm64"` and a `t4g`/`c7g` instance to reduce cost
      and attack surface.
- [ ] Run the module in a private subnet behind NAT and front it with a
      Tailscale/WireGuard relay if you do not need a public server.
