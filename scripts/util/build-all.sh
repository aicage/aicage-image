#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

die() {
  echo "[build-all] $*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: scripts/util/build-all.sh [build-options]

Builds the full matrix of <tool>-<base> combinations. Any options after the script name are
forwarded to scripts/util/build.sh for each build.

Options:
  -h, --help          Show this help and exit
USAGE
  exit 1
}

# shellcheck source=../scripts/common.sh
source "${ROOT_DIR}/scripts/common.sh"

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
fi

PUSHED_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      ;;
    *)
      PUSHED_ARGS+=("$1")
      shift
      ;;
  esac
done

load_config_file

TOOLS_DIR="${ROOT_DIR}/tools"
AICAGE_BASE_ALIASES="${AICAGE_BASE_ALIASES:-$(discover_base_aliases)}"

for tool_dir in "${TOOLS_DIR}"/*; do
  tool="$(basename "${tool_dir}")"
  for base_alias in ${AICAGE_BASE_ALIASES}; do
    echo "[build-all] Building ${tool}-${base_alias}" >&2
    "${ROOT_DIR}/scripts/util/build.sh" \
      --tool "${tool}" \
      --base "${base_alias}" \
      "${PUSHED_ARGS[@]}"
  done
done
