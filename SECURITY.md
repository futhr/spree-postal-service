# Security policy

Security reports should not be filed as public issues when they disclose an exploitable vulnerability.

Use GitHub private vulnerability reporting when available for this repository. If that is unavailable, contact the maintainers through the address published in the gemspec.

The supported modernization target is the `main` branch against the currently documented Solidus compatibility matrix. Historical releases and the `master` branch are preserved for provenance and are not receiving security fixes.

Please include the affected version/commit, Solidus/Ruby versions, reproduction steps, impact, and any proposed mitigation. Do not include real customer data or credentials.

## Dependency auditing

CI and the weekly security workflow update the Ruby advisory database and fail
on vulnerable dependencies. Dependabot checks both Bundler and GitHub Actions
weekly.

Two narrowly scoped audit exceptions are currently recorded for
`CVE-2026-47736` and `CVE-2026-47737`. Both affect Puma's PROXY protocol v1
parser. Puma is present only through `solidus_dev_support` for the generated
test server, that server does not enable PROXY protocol, and Puma is excluded
from the published gem's runtime dependency graph. `solidus_dev_support` 2.12
constrains Puma below 7, while patched versions begin at 7.2.1 and 8.0.2. The
exceptions must be removed as soon as upstream permits a patched Puma; they do
not authorize ignoring any other advisory.
