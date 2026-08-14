# mirror-bazel-lsp

OCX mirror for [bazel-lsp](https://github.com/cameron-martin/bazel-lsp) — a
language server for Bazel. One repository, one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [bazel-lsp](https://github.com/cameron-martin/bazel-lsp) | [`bazel-lsp/mirror.yml`](bazel-lsp/mirror.yml) | `ghcr.io/ocx-contrib/bazel-lsp/bazel-lsp` | `ocx.sh/bazel-lsp/bazel-lsp` | `Apache-2.0` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

## Layout

```
bazel-lsp/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

There is no `mirror-base.yml`: with a single package every key is
package-owned, so the whole spec lives in `bazel-lsp/mirror.yml`. Adding a base
when a second package arrives is a content move that renames no generated
workflow file. If you do add one, remember `extends:` is a **shallow** merge of
top-level keys — a spec that restates `platforms:` to change one runner drops
every `containers:` entry with it, and nothing reds: the legs simply stop
existing, and every `os.features` claim goes back to being asserted rather than
verified.

## The namespace

`bazel-lsp/bazel-lsp`, not `cameron-martin/bazel-lsp`. The namespace carries
identity, not provenance — a solo tool published under a personal handle names
itself, because a maintainer handle ages badly (mirroring jq in 2022 would have
produced `stedolan/jq`). Provenance is recorded verifiably in the index claim's
`upstream.{org, repository_url, disclaimer}` block.

It is also **not** under `bazelbuild/`. That namespace is the Bazel project's
own identity, and this is a third-party tool.

## Platforms

Upstream added platforms over time, so the late arrivals carry a per-platform
`min_version` rather than the catalog floor being bumped to dodge them. An
out-of-window `(version, platform)` is never resolved, built, tested or pushed,
and never reds the run.

| Platform | Upstream since | In this mirror |
|---|---|---|
| `linux/amd64+libc.glibc` | 0.1.1 | from the 0.6.0 floor |
| `darwin/amd64` | 0.3.0 | from the 0.6.0 floor |
| `darwin/arm64` | 0.3.1 | from the 0.6.0 floor |
| `windows/amd64` | 0.6.2 | `min_version: 0.6.2` |
| `linux/arm64+libc.glibc` | 0.6.4 | `min_version: 0.6.4` |

**Both Linux keys carry `+libc.glibc`.** `os.features` states what an artifact
requires *of the host*, and these binaries are dynamically linked: `PT_INTERP`
is `/lib64/ld-linux-x86-64.so.2` on amd64 and `/lib/ld-linux-aarch64.so.1` on
arm64, with `libc.so.6` in `DT_NEEDED` on both. The measurement is recorded
above `assets:` in the spec. Upstream ships no musl build, so there is no bare
key to publish alongside — and **no alpine container leg**: the renderer
rejects a musl image under a `+libc.glibc` key, correctly, since this artifact
genuinely cannot load there. The glibc floor is `GLIBC_2.17` on both arches
(measured separately — they come off different toolchains); `ubuntu:24.04` and
`fedora:40` clear it by a wide margin.

macOS assets are per-arch Mach-O (no universal binary) and Windows is `PE32+`;
neither has a libc family to qualify.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `bazel-lsp/mirror.yml` | hand | yes — see below |
| `bazel-lsp/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `bazel-lsp/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec bazel-lsp/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

bazel-lsp ships as a raw binary, so the bundle's only PATH entry is a bare
`${installPath}` — the executable *is* the content root. `bin_scan` only looks
*below* an `${installPath}/<dir>` entry, so `auto`/`verify` is rejected at spec
load with exit 65. The spec therefore sets `bin_scan: off` and
`bazel-lsp/metadata.json` hand-lists `binaries: ["bazel-lsp"]` — the blessed
shape for this asset type.

The upstream asset name embeds the version (`bazel-lsp-0.6.4-linux-amd64`), so
`asset_type.name` renames it to the bare tool name; the Windows override adds
the `.exe` suffix the asset already carries.

## Why the smoke test speaks JSON-RPC

bazel-lsp is a language server: its contract is the LSP wire protocol on
stdio, not a subcommand. `bazel-lsp/tests/smoke.star` drives a real session —
`initialize` → `initialized` → `shutdown` → `exit` with `Content-Length`
framing — and asserts the server's own capability advertisement
(`definitionProvider`, `completionProvider`, `hoverProvider`) comes back. A
truncated or wrong-arch artifact cannot answer `initialize`; a `--version`
assertion alone would pass for a binary that does nothing else.

The server shells out to `bazel` for workspace queries, but **not** during a
session opened with `rootUri: null`, so the test needs no `bazel` in the
container legs. Measured on v0.6.4 with no bazel installed: exit 0, three
frames back.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; the
redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
