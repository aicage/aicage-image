#!/usr/bin/env bash
set -euo pipefail

curl -fsSL https://api.github.com/repos/block/goose/releases/latest \
  | jq -r '.name | ltrimstr("v")'
