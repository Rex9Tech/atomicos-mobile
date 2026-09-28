#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Ensure developer toolchains are discoverable in GUI environments (VS Code, Fork, SourceTree)
if ! command -v dart &>/dev/null; then
  for p in \
    "$HOME/Desktop/Dev/Dependencies/flutter/bin" \
    "$HOME/development/flutter/bin" \
    "$HOME/flutter/bin" \
    "/opt/homebrew/bin" \
    "/usr/local/bin" \
    "$HOME/.pub-cache/bin"
  do
    if [ -x "$p/dart" ]; then
      export PATH="$p:$PATH"
      break
    fi
  done
fi

if ! command -v dart &>/dev/null; then
  echo "⚠️ Warning: 'dart' not found in PATH. Skipping locale check in GUI environment."
  exit 0
fi

dart run scripts/check_locales.dart "$@"
