# Security policy

## Supported versions

Security fixes are made on `main` for the Ruby and Solidus versions in the
[supported matrix](docs/testing.md#supported-matrix). Historical releases and
the preserved `master` branch are not maintained.

## Report a vulnerability

Please do not open a public issue for an exploitable vulnerability. Use GitHub
private vulnerability reporting for this repository. If that is unavailable,
contact the maintainers at an address published in the gemspec.

Include the affected version or commit, Solidus and Ruby versions, reproduction
steps, likely impact, and any proposed mitigation. Never include real customer
data, credentials, or secrets.

## Dependency auditing

CI and the weekly security workflow update the Ruby advisory database and fail
on vulnerable dependencies. Dependabot checks both Bundler and GitHub Actions
weekly.

Two narrowly scoped, temporary audit exceptions are currently recorded for
`CVE-2026-47736` and `CVE-2026-47737`. Both affect Puma's PROXY protocol v1
parser. Puma is present only through `solidus_dev_support` for the generated
test server, that server does not enable PROXY protocol, and Puma is excluded
from the published gem's runtime dependency graph. `solidus_dev_support` 2.12
constrains Puma below 7, while patched versions begin at 7.2.1 and 8.0.2. The
exceptions must be removed as soon as upstream permits a patched Puma. They do
not authorize ignoring any other advisory.
