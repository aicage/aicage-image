#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

die() {
  echo "[build] $*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: scripts/util/build.sh --tool <tool> --base <alias> [options]

Options:
  --tool <value>       Tool name to build (required)
  --base <value>       Base alias to consume (required; must match available base tags)
  --version <value>    Override AICAGE_VERSION for this build
  -h, --help           Show this help and exit

Examples:
  scripts/util/build.sh --tool cline --base fedora
  scripts/util/build.sh --tool codex --base ubuntu --version dev
USAGE
  exit 1
}

# shellcheck source=../scripts/common.sh
source "${ROOT_DIR}/scripts/common.sh"

TOOL=""
BASE_ALIAS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool)
      [[ $# -ge 2 ]] || die "--tool requires a value"
      TOOL="$2"
      shift 2
      ;;
    --base)
      [[ $# -ge 2 ]] || die "--base requires a value"
      BASE_ALIAS="$2"
      shift 2
      ;;
    --version)
      [[ $# -ge 2 ]] || die "--version requires a value"
      AICAGE_VERSION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    --)
      shift
      break
      ;;
    *)
      die "Unknown option '$1'"
      ;;
  esac
done

[[ -n "${TOOL}" && -n "${BASE_ALIAS}" ]] || die "--tool and --base are required"

load_config_file

BASE_IMAGE="${AICAGE_IMAGE_BASE_REPOSITORY}:${BASE_ALIAS}-latest"
VERSION_TAG="${AICAGE_REPOSITORY}:${TOOL}-${BASE_ALIAS}-${AICAGE_VERSION}"
LATEST_TAG="${AICAGE_REPOSITORY}:${TOOL}-${BASE_ALIAS}-latest"
DESCRIPTION="Agent image for ${TOOL}"
TOOL_PATH_LABEL="$(get_tool_field "${TOOL}" tool_path)"

(
  echo "[build] Tool=${TOOL}"
  echo "Base=${BASE_ALIAS}"
  echo "Repo=${AICAGE_REPOSITORY}"
  echo "Version=${AICAGE_VERSION}"
  echo "BaseImage=${BASE_IMAGE}"
  echo "Tags=${VERSION_TAG},${LATEST_TAG}"
) >&2

docker build \
  --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
  --build-arg "TOOL=${TOOL}" \
  --label "tool_path=${TOOL_PATH_LABEL}" \
  --label "org.opencontainers.image.description=${DESCRIPTION}" \
  --tag "${VERSION_TAG}" \
  --tag "${LATEST_TAG}" \
  "${ROOT_DIR}"
