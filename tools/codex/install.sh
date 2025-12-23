#!/usr/bin/env bash
set -euo pipefail

npm install -g @openai/codex

install -d /usr/share/licenses/codex
curl -fsSL https://raw.githubusercontent.com/openai/codex/main/LICENSE \
  -o /usr/share/licenses/codex/LICENSE
