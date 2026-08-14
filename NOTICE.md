# NOTICE

This repository packages and redistributes upstream software published by
[cameron-martin/bazel-lsp](https://github.com/cameron-martin/bazel-lsp). The
Apache-2.0 license in [`LICENSE`](LICENSE) covers the OCX pipeline files
authored here. It does **not** cover any upstream-derived asset — each
package's redistributed bytes carry their own license, recorded below.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `bazel-lsp` | `ghcr.io/ocx-contrib/bazel-lsp/bazel-lsp` | `Apache-2.0` |

---

## `bazel-lsp`

Upstream: <https://github.com/cameron-martin/bazel-lsp>
Published to `ghcr.io/ocx-contrib/bazel-lsp/bazel-lsp`.

| Component | SPDX | Holder |
|---|---|---|
| bazel-lsp (`bazel-lsp`) | **Apache-2.0** | Cameron Martin and contributors |

Permissive. Apache-2.0 §4 grants redistribution of the Object form provided the
license is conveyed and modifications are stated. Upstream ships raw binaries
with no bundled license file, so the terms are those of
<https://github.com/cameron-martin/bazel-lsp/blob/master/LICENSE>. Upstream
publishes no `NOTICE` file, so there is none to propagate under §4(d).

The published binaries statically link third-party Rust crates under permissive
licenses, enumerated in upstream's `Cargo.toml` / `Cargo.lock` — notably
[starlark-rust](https://github.com/facebookexperimental/starlark-rust)
(Apache-2.0), which this tool is built on.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle. The asset is renamed from
`bazel-lsp-<version>-<os>-<arch>` to `bazel-lsp` so it resolves on `PATH`; the
bytes are unchanged.

`bazel-lsp/logo.svg` and `bazel-lsp/logo.png` are original marks authored for
the OCX catalog — upstream ships no logo. They are deliberately **not** derived
from the Bazel project's trademarks: bazel-lsp is a third-party tool, and no
affiliation with or endorsement by the Bazel project is implied. "Bazel" is a
trademark of Google LLC and is used here only to name the build system this
tool targets.
