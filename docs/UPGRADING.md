# Upgrading

## v1.x -> v2.0

v2 is a breaking release. Read this whole page before upgrading; existing
servers will be replaced if you do not follow the migration path.

### 1. Move the provider out of the module

The module no longer declares its own provider. Add this to your root config
(or wherever you call the module):

```hcl
terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1" # whatever you previously passed as var.region
}
```

### 2. Update module inputs

| v1 input          | v2 replacement                                                                  |
| ----------------- | ------------------------------------------------------------------------------- |
| `region`          | Removed - configure on the provider in the root module.                         |
| `personal_ip`     | `allowed_ssh_cidrs = ["1.2.3.4/32"]` (only when `ssh_enabled = true`).          |
| `personal_subnet` | Encoded as the prefix length in the CIDR entries above.                         |
| _new_             | `subnet_id` is now required.                                                    |
| _new_             | `eula_accepted = true` is required.                                             |

Example diff:

```hcl
 module "minecraft" {
   source  = "kn-lim/minecraft/aws"
-  version = "~> 1.0"
+  version = "~> 2.0"

-  region          = "us-west-2"
   name            = "minecraft"
   instance_type   = "t3.small"
   server_url      = "https://piston-data.mojang.com/v1/objects/.../server.jar"
   java_max_memory = 1024
-  personal_ip     = "203.0.113.1"
-  personal_subnet = "32"
+
+  subnet_id     = "subnet-0123456789abcdef0"
+  eula_accepted = true
+
+  # Optional, only if you really want SSH:
+  ssh_enabled       = true
+  allowed_ssh_cidrs = ["203.0.113.1/32"]
+  key_pair_name     = "minecraft"
 }
```

### 3. State migration

Resource renames are handled automatically by `moved {}` blocks. Run:

```bash
terraform init -upgrade
terraform plan
```

Expected plan output:

- Resources are renamed via `moved` (no destroy/create).
- Inline ingress/egress on the SG are replaced by dedicated rule resources.
  This is a refactor; the SG itself is preserved.
- The instance shows in-place changes for `metadata_options` (IMDSv2),
  `root_block_device` (encryption), `iam_instance_profile`, and `user_data`.

`user_data_replace_on_change = true` means **the instance will be replaced**.
If your world is on the root volume, back it up first:

```bash
aws ssm start-session --target <instance-id>
sudo tar -czf /tmp/world.tgz -C /opt/minecraft world world_nether world_the_end
aws s3 cp /tmp/world.tgz s3://your-backup-bucket/
```

After upgrade, restore on the new instance, or set
`persistent_storage_enabled = true` from the start to avoid this in future.

### 4. SSH vs SSM

v2 disables SSH by default. The instance has SSM agent + the IAM role to use
it. To shell in:

```bash
aws ssm start-session --target $(terraform output -raw instance_id)
```

If you still need SSH, set `ssh_enabled = true`, `allowed_ssh_cidrs`, and
`key_pair_name`.
