# Complete example

Production-style configuration: Graviton (arm64) instance with persistent EBS
data volume, Elastic IP, Route 53 DNS, scoped SSH ingress, and richer JVM heap.

Resolve the latest server.jar URL from Mojang:

```bash
SERVER_URL=$(curl -fsSL https://launchermeta.mojang.com/mc/game/version_manifest_v2.json \
  | jq -r '.latest.release as $r | .versions[] | select(.id==$r) | .url' \
  | xargs curl -fsSL | jq -r '.downloads.server.url')
```

Then:

```bash
terraform init
terraform apply \
  -var="subnet_id=subnet-0123456789abcdef0" \
  -var="server_url=$SERVER_URL" \
  -var="key_pair_name=my-key" \
  -var="my_ip_cidr=203.0.113.1/32" \
  -var="route53_zone_id=Z01234567ABCDEF" \
  -var="route53_record_name=mc.example.com"
```

> Note: this uses Graviton (arm64). If you want x86_64 instead, drop
> `architecture = "arm64"` and `instance_type = "t4g.medium"` from `main.tf`
> (or override the variables) — defaults pick up `t3.small` on `x86_64`.

After apply, players connect to `mc.example.com:25565`. Operators connect via:

```bash
aws ssm start-session --target $(terraform output -raw instance_id)
```
