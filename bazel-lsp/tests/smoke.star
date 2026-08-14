# Stable smoke test — assert on the contract (exit codes, version shape, a real
# LSP session), never on help/version prose. Upstream rewords its clap help
# freely; the version digits and the JSON-RPC capability keys below are API.
#
# ⚠️ NO top-level `if`/`for`/`while` STATEMENTS — `ocx package test` runs the
# Bazel .bzl Starlark dialect, where a control-flow statement at module scope is
# a PARSE error that reds every version on every platform before an assertion
# runs. Branch with an if-EXPRESSION (below) or inside a `def`.
TOOL = "bazel-lsp.exe" if ocx.target_platform.os == ocx.os.Windows else "bazel-lsp"

# Tier 1: liveness. Exit code only, never the help text.
expect.ok(ocx.run(TOOL, "--help"))

# ⚠️ NO `--version` ASSERTION, AND THAT IS DELIBERATE. Upstream does not ship
# the flag on every platform: from 0.6.2 on, the osx-arm64 and windows builds
# have no `-V/--version` at all, while the linux and osx-amd64 builds of the
# same releases do. Measured 2026-08-14 on real runners, all five in-range
# versions (probe run 31794652305 and its predecessor):
#
#   platform      0.6.0        0.6.1        0.6.2 / 0.6.3 / 0.6.4
#   linux-amd64   rc=0         rc=0         rc=0
#   osx-amd64     rc=0         rc=0         rc=0
#   osx-arm64     rc=0         rc=0         rc=2  error: unexpected argument
#   windows       (no asset)   (no asset)   rc=2  error: unexpected argument
#
# Their `--help` mentions "version" zero times — the flag is genuinely absent,
# not renamed. And where it IS present it is not trustworthy: 0.6.0 reports
# `bazel-lsp 0.0.0` on both macOS slices, so the version stamp is missing from
# that build too.
#
# Every one of those builds answers a full LSP session correctly (same probe:
# rc=0, all three capabilities, shutdown honoured), so this is a CLI-surface
# difference, not a bad artifact. Asserting the flag would exclude five working
# platform tiles to test something upstream never promised. The session below
# is the tool's actual contract and a strictly stronger check.

# Tier 2 + 3: COMPUTED work. bazel-lsp is a language server, so its contract is
# the LSP wire protocol on stdin/stdout, not a subcommand. Drive a full session
# — initialize → initialized → shutdown → exit — with Content-Length framing
# and assert the server's own capability advertisement comes back.

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
