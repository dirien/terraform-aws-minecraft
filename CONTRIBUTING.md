# Contributing

Thanks for considering a contribution.

## Development setup

```bash
# install once
brew install terraform tflint terraform-docs trivy pre-commit
pre-commit install
```

## Local checks

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
terraform test
tflint --recursive
trivy config .
terraform-docs .
```

CI runs all of the above on every PR.

## Adding inputs/outputs

- Add a `variable` block with `description`, `type`, and `validation` where it
  makes sense.
- Update both example modules if the new input is user-facing.
- Add or extend a test in `tests/` to assert the new behaviour.
- Run `terraform-docs .` (or let CI/pre-commit run it) to refresh the README.

## Renaming resources

- Add a `moved {}` block from the old address to the new one. Do not skip
  this -- it protects every existing user from a destroy/create cycle.

## Releasing

- Follow [Semantic Versioning](https://semver.org/):
  - `MAJOR` for breaking changes (resource renames without `moved`, removed
    inputs, changed defaults that destroy resources).
  - `MINOR` for new features.
  - `PATCH` for fixes.
- Add an entry to `CHANGELOG.md` under `[Unreleased]`. release-please will
  open a release PR that promotes it.
