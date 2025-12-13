#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

die() {
  echo "[build-all] $*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: scripts/build-all.sh [build-options]

Builds the full matrix of <tool>-<base> combinations. Any options after the script name are
forwarded to scripts/build.sh for each build (e.g., --platform). Platforms must come from --platform
or environment (.env).

Options:
  --platform <value>  Build only a single platform (e.g., linux/amd64)
  --push              Push images instead of loading locally
  --version <value>   Override AICAGE_VERSION for this sweep
  -h, --help          Show this help and exit
USAGE
  exit 1
}

# shellcheck source=../scripts/common.sh
source "${ROOT_DIR}/scripts/common.sh"

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
fi

load_env_file

PUSH_FLAG=

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)
      [[ $# -ge 2 ]] || { echo "[build-all] --platform requires a value" >&2; exit 1; }
      AICAGE_PLATFORMS="$2"
      shift 2
      ;;
    --push)
      PUSH_FLAG="--push"
      shift
      ;;
    --version)
      [[ $# -ge 2 ]] || { echo "[build-all] --version requires a value" >&2; exit 1; }
      AICAGE_VERSION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      die "Unexpected argument '$1'"
      ;;
  esac
done

AICAGE_BASE_ALIASES="${AICAGE_BASE_ALIASES:-$(discover_base_aliases)}"
echo "[build-all] Building platforms ${AICAGE_PLATFORMS}." >&2

for tool in ${AICAGE_TOOLS}; do
  for base_alias in ${AICAGE_BASE_ALIASES}; do
    echo "[build-all] Building ${tool}-${base_alias} (platforms: ${AICAGE_PLATFORMS})" >&2
    "${ROOT_DIR}/scripts/build.sh" \
      --tool "${tool}" \
      --base "${base_alias}" \
      --platform "${AICAGE_PLATFORMS}" \
      --version "${AICAGE_VERSION}" \
      ${PUSH_FLAG}
  done
done
