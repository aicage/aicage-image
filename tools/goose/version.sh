#!/usr/bin/env bash
set -euo pipefail

python3 -m pip index versions goose-ai 2>/dev/null \
  | sed -n 's/^goose-ai (\(.*\))/\1/p'

# alternative with curl and jq
# curl -fsSL https://pypi.org/pypi/goose-ai/json \
#   | jq -r '.info.version'

