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
  -h, --help           Show this help and exit

Examples:
  scripts/util/build.sh --tool cline --base fedora
  scripts/util/build.sh --tool codex --base ubuntu
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

BASE_IMAGE="${AICAGE_IMAGE_REGISTRY}/${AICAGE_IMAGE_BASE_REPOSITORY}:${BASE_ALIAS}-latest"
TOOL_VERSION="$("${ROOT_DIR}/tools/${TOOL}/version.sh")"
[[ -n "${TOOL_VERSION}" ]] || die "Tool version is empty for ${TOOL}"
VERSION_TAG="${AICAGE_IMAGE_REPOSITORY}:${TOOL}-${BASE_ALIAS}-${TOOL_VERSION}"
LATEST_TAG="${AICAGE_IMAGE_REPOSITORY}:${TOOL}-${BASE_ALIAS}-latest"
TOOL_PATH="$(get_tool_field "${TOOL}" tool_path)"
TOOL_FULL_NAME="$(get_tool_field "${TOOL}" tool_full_name)"
TOOL_HOMEPAGE="$(get_tool_field "${TOOL}" tool_homepage)"

(
  echo "[build] Tool=${TOOL}"
  echo "Base=${BASE_ALIAS}"
  echo "Repo=${AICAGE_IMAGE_REPOSITORY}"
  echo "Version=${TOOL_VERSION}"
  echo "BaseImage=${BASE_IMAGE}"
  echo "Tags=${VERSION_TAG},${LATEST_TAG}"
) >&2

docker build \
  --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
  --build-arg "TOOL=${TOOL}" \
  --label "org.opencontainers.image.description=Agent image for ${TOOL}" \
  --label "org.aicage.tool.tool_path=${TOOL_PATH}" \
  --label "org.aicage.tool.tool_full_name=${TOOL_FULL_NAME}" \
  --label "org.aicage.tool.tool_homepage=${TOOL_HOMEPAGE}" \
  --tag "${VERSION_TAG}" \
  --tag "${LATEST_TAG}" \
  "${ROOT_DIR}"
