#!/bin/bash
# FST / CenVu | (+84) 842 841 222
#
# fst-codegraph — project-scoped CodeGraph MCP server wrapper for FST.
#
# Pinned runtime: @astudioplus/codegraph-mcp@0.19.1 (exact version)
# Native binary : codegraph-server-darwin-arm64 v0.19.1 (ef6a466)
# Official origin: https://github.com/codegraph-ai/CodeGraph (Apache-2.0)
# Install location: $HOME/.local/share/fst-codegraph-mcp (outside this repo)
#
# This wrapper starts ONLY the official pinned CodeGraph MCP server, scoped to
# the FST repository root, over stdio. stdout is reserved for MCP JSON-RPC.
# All diagnostics go to stderr. It exits nonzero on invalid setup.

set -euo pipefail

# Resolve repository root from the script location, not the caller's cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Hard scope: refuse to serve any other directory.
EXPECTED_ROOT="/Users/cenvu/DEV/FST_V2"
if [[ "$REPO_ROOT" != "$EXPECTED_ROOT" ]]; then
  echo "fst-codegraph: refusing to serve $REPO_ROOT (expected $EXPECTED_ROOT)" >&2
  exit 1
fi
if [[ ! -f "$REPO_ROOT/AGENTS.md" || ! -d "$REPO_ROOT/FishSockTransfer" ]]; then
  echo "fst-codegraph: $REPO_ROOT does not look like the FST repository" >&2
  exit 1
fi

# Pinned official runtime (installed outside the repo; exact version 0.19.1).
INSTALL_DIR="${HOME}/.local/share/fst-codegraph-mcp"
BINARY="${INSTALL_DIR}/node_modules/@astudioplus/codegraph-mcp/bin/codegraph-server-darwin-arm64"

if [[ ! -x "$BINARY" ]]; then
  echo "fst-codegraph: pinned runtime not found at $BINARY" >&2
  echo "fst-codegraph: reinstall with:" >&2
  echo "  npm install --prefix \"$INSTALL_DIR\" --no-fund --no-audit @astudioplus/codegraph-mcp@0.19.1" >&2
  exit 1
fi

# Anonymous telemetry off (documented opt-out of the official package).
export CODEGRAPH_TELEMETRY=off

# stdio MCP server. Workspace scoped to this repository; build artifacts and
# sensitive areas excluded. Profile "all" is required: no narrower profile
# exposes the full pre-edit tool set (symbol search, AI/edit context, callers,
# callees, dependency graph, impact analysis, related tests, reindex).
exec "$BINARY" --mcp \
  --workspace "$REPO_ROOT" \
  --exclude .git \
  --exclude DerivedData \
  --exclude build \
  --exclude dist \
  --exclude archives \
  --profile all
