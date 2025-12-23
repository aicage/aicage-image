#!/usr/bin/env bash
set -euo pipefail

npm install -g opencode-ai

install -d /usr/share/licenses/opencode
curl -fsSL https://opencode.ai/legal/terms-of-service \
  -o /usr/share/licenses/opencode/TERMS.html
