#!/usr/bin/env bash
set -euo pipefail

npm install -g cline

install -d /usr/share/licenses/cline
curl -fsSL https://raw.githubusercontent.com/cline/cline/main/LICENSE \
  -o /usr/share/licenses/cline/LICENSE
