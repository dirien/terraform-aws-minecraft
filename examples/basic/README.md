# Basic example

Minimal configuration: launches a Minecraft server in the default VPC, accessible
via SSM Session Manager (no SSH, no key pair required).

Find the latest server.jar URL from Mojang:

```bash
SERVER_URL=$(curl -fsSL https://launchermeta.mojang.com/mc/game/version_manifest_v2.json \
  | jq -r '.latest.release as $r | .versions[] | select(.id==$r) | .url' \
  | xargs curl -fsSL | jq -r '.downloads.server.url')
echo "$SERVER_URL"
```

Then:

```bash
terraform init
terraform apply -var="server_url=$SERVER_URL"
```

When done:

```bash
terraform destroy
```
