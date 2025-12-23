#!/usr/bin/env bash
set -euo pipefail

npm install -g @charmland/crush

install -d /usr/share/licenses/crush
curl -fsSL https://raw.githubusercontent.com/charmbracelet/crush/main/LICENSE.md \
  -o /usr/share/licenses/crush/LICENSE.md
