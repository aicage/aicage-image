#!/usr/bin/env bash
set -euo pipefail

curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | \
  GOOSE_BIN_DIR=/usr/local/bin \
  CONFIGURE=false \
  bash
