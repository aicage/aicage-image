#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

die() {
  echo "[build] $*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: scripts/build.sh --tool <tool> --base <alias> [options]

Options:
  --tool <value>       Tool name to build (required)
  --base <value>       Base alias to consume (required; must match available base tags)
  --platform <value>   Override platform list (default: env or linux/amd64,linux/arm64)
  --push               Push the image instead of loading it locally
  --version <value>    Override AICAGE_VERSION for this build
  -h, --help           Show this help and exit

Examples:
  scripts/build.sh --tool cline --base fedora
  scripts/build.sh --tool codex --base node --platform linux/amd64
USAGE
  exit 1
}

# shellcheck source=../scripts/common.sh
source "${ROOT_DIR}/scripts/common.sh"

PUSH_MODE="--load"
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
    --platform)
      [[ $# -ge 2 ]] || die "--platform requires a value"
      AICAGE_PLATFORMS="$2"
      shift 2
      ;;
    --push)
      PUSH_MODE="--push"
      shift
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

load_env_file

TARGET="${TOOL}-${BASE_ALIAS}"
BASE_IMAGE="${AICAGE_BASE_REPOSITORY}:${BASE_ALIAS}-latest"
TAG="${AICAGE_REPOSITORY}:${TOOL}-${BASE_ALIAS}-latest"
DESCRIPTION="Agent image for ${TOOL}"

echo "[build] Target=${TARGET} Platforms=${AICAGE_PLATFORMS} Repo=${AICAGE_REPOSITORY} Tag=${TAG} BaseImage=${BASE_IMAGE} Mode=${PUSH_MODE}" >&2
env \
  "AICAGE_REPOSITORY=${AICAGE_REPOSITORY}" \
  "AICAGE_VERSION=${AICAGE_VERSION}" \
  "AICAGE_PLATFORMS=${AICAGE_PLATFORMS}" \
  docker buildx bake \
    -f "${ROOT_DIR}/docker-bake.hcl" \
    agent \
    --set "agent.args.BASE_IMAGE=${BASE_IMAGE}" \
    --set "agent.args.TOOL=${TOOL}" \
    --set "agent.tags=${TAG}" \
    --set "agent.labels.org.opencontainers.image.description=${DESCRIPTION}" \
    "${PUSH_MODE}"
