# Stable smoke test — assert on the contract (exit codes, version shape, a real
# LSP session), never on help/version prose. Upstream rewords its clap help
# freely; the version digits and the JSON-RPC capability keys below are API.
#
# ⚠️ NO top-level `if`/`for`/`while` STATEMENTS — `ocx package test` runs the
# Bazel .bzl Starlark dialect, where a control-flow statement at module scope is
# a PARSE error that reds every version on every platform before an assertion
# runs. Branch with an if-EXPRESSION (below) or inside a `def`.
TOOL = "bazel-lsp.exe" if ocx.target_platform.os == ocx.os.Windows else "bazel-lsp"

# Tier 1 + 2: liveness + version SHAPE — not the vendor string, not the exact
# version. `bazel-lsp --version` prints `bazel-lsp <semver>`.
r_version = ocx.run(TOOL, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# A separate code path from `--version` — exit code only, never the help text.
expect.ok(ocx.run(TOOL, "--help"))

# Tier 3: COMPUTED work. bazel-lsp is a language server, so its contract is the
# LSP wire protocol on stdin/stdout, not a subcommand. Drive a full session —
# initialize → initialized → shutdown → exit — with Content-Length framing and
# assert the server's own capability advertisement comes back.
#
# This is what distinguishes a working binary from one that merely starts: a
# truncated or wrong-arch artifact cannot answer `initialize`, and a binary that
# only printed a version would produce no frames at all.
#
# `bazel` is NOT on PATH in the container legs and is not needed: with
# `rootUri: null` the server never shells out to it. Measured on v0.6.4 with no
# bazel installed — exit 0, three frames back.

def frame(body):
    # LSP header framing: byte length, CRLF CRLF, then the JSON body. The
    # bodies are pure ASCII, so len() in characters equals the byte count.
    return "Content-Length: " + str(len(body)) + "\r\n\r\n" + body

INIT = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":null,"rootUri":null,"capabilities":{}}}'
INITIALIZED = '{"jsonrpc":"2.0","method":"initialized","params":{}}'
SHUTDOWN = '{"jsonrpc":"2.0","id":2,"method":"shutdown"}'
EXIT = '{"jsonrpc":"2.0","method":"exit"}'

SESSION = frame(INIT) + frame(INITIALIZED) + frame(SHUTDOWN) + frame(EXIT)

r_lsp = ocx.run(TOOL, stdin = SESSION)
expect.ok(r_lsp)

# The server framed its replies — the transport half of the contract.
expect.contains(r_lsp.stdout, "Content-Length:")

# It answered the request it was given, not some other one.
expect.contains(r_lsp.stdout, '"id":1')

# The capabilities this tool exists to provide. These are protocol keys from
# the LSP spec, stable across releases — losing one is a functional regression,
# not a rewording.
expect.contains(r_lsp.stdout, '"definitionProvider"')
expect.contains(r_lsp.stdout, '"completionProvider"')
expect.contains(r_lsp.stdout, '"hoverProvider"')

# It stayed alive past `initialize` and honoured `shutdown` — a server that
# crashed on the first frame would still have emitted the reply above.
expect.contains(r_lsp.stdout, '"id":2')
