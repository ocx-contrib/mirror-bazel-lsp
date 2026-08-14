---
title: bazel-lsp
description: Language server for Bazel — go-to-definition, autocomplete and auto-import across BUILD, .bzl and MODULE.bazel files
keywords: bazel,lsp,language-server,starlark,build,bzl,ide,editor,starlark-rust
---

# bazel-lsp

A [Language Server Protocol](https://microsoft.github.io/language-server-protocol/)
implementation for Bazel, built on
[starlark-rust](https://github.com/facebookexperimental/starlark-rust). It gives
any LSP-capable editor real navigation across a Bazel workspace instead of plain
text search.

## Features

- **Go to definition** — for both Starlark identifiers and Bazel *labels*, so
  `//pkg:target` and `@repo//pkg:target` jump to the rule that declares them.
- **Autocomplete** — identifiers and labels, resolved against the workspace via
  `bazel query`.
- **Auto-import** — inserts the missing `load()` statement (currently for
  symbols in open files).

## What's included

- **bazel-lsp** — the language server itself. Speaks LSP over stdio; it is
  started by your editor, not run interactively.

## Setup

The server shells out to `bazel` for workspace queries, so **`bazel` (or
`bazelisk`) must be on `PATH`** — or pointed at explicitly with
`--bazel <path>`. Queries use a separate output base by default so they do not
block concurrent builds; `--no-distinct-output-base` disables that, and
`--query-output-base <dir>` relocates it.

With the
[Bazel VS Code extension](https://marketplace.visualstudio.com/items?itemName=BazelBuild.vscode-bazel)
installed, point it at the server:

```json
{
  "bazel.lsp.command": "bazel-lsp"
}
```

Logging is controlled by the `RUST_LOG` environment variable
(`tracing_subscriber` filter syntax), which the VS Code extension can set via
`"bazel.lsp.env": { "RUST_LOG": "info" }`.

## Links

- [bazel-lsp on GitHub](https://github.com/cameron-martin/bazel-lsp)
- [Changelog](https://github.com/cameron-martin/bazel-lsp/blob/master/CHANGELOG.md)
- [starlark-rust](https://github.com/facebookexperimental/starlark-rust)
