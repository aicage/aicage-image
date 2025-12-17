#!/usr/bin/env bash
set -euo pipefail

# Install Goose CLI using the official installer.
export HOME=/root

curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash

# Ensure the binary is on the global PATH for the runtime user.
if [[ -x "/root/.local/bin/goose" ]]; then
  install -m 0755 /root/.local/bin/goose /usr/local/bin/goose
elif command -v goose >/dev/null 2>&1; then
  # Fallback: copy whatever the installer placed on PATH.
  install -m 0755 "$(command -v goose)" /usr/local/bin/goose
fi

if ! command -v goose >/dev/null 2>&1; then
  echo "[install_goose] 'goose' executable not found after installation." >&2
  exit 1
fi
