#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

die() {
  echo "[test-all] $*" >&2
  exit 1
}

# shellcheck source=../scripts/common.sh
source "${ROOT_DIR}/scripts/common.sh"

load_env_file

AICAGE_BASE_ALIASES="${AICAGE_BASE_ALIASES:-$(discover_base_aliases)}"

for TOOL in ${AICAGE_TOOLS}; do
  for BASE_ALIAS in ${AICAGE_BASE_ALIASES}; do
    IMAGE="${AICAGE_REPOSITORY}:${TOOL}-${BASE_ALIAS}-latest"
    echo "[test-all] Testing ${IMAGE}" >&2
    "${ROOT_DIR}/scripts/test.sh" --image "${IMAGE}" -- "$@"
  done
done
