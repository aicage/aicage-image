#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/generate-images-metadata.sh --output <path> --image-tag <tag> [options]

Options:
  --config <path>      Path to config.yaml (default: config.yaml)
  --agents-dir <path>  Path to agents directory (default: agents)
  --output <path>     Output YAML file path (required)
  --image-tag <value> Release tag for aicage-image (required)
  -h, --help          Show this help and exit
USAGE
  exit 1
}

die() {
  echo "[generate-images-metadata] $*" >&2
  exit 1
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_PATH="${ROOT_DIR}/config.yaml"
AGENTS_DIR="${ROOT_DIR}/agents"
OUTPUT_PATH=""
IMAGE_TAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      [[ $# -ge 2 ]] || die "--config requires a value"
      CONFIG_PATH="$2"
      shift 2
      ;;
    --agents-dir)
      [[ $# -ge 2 ]] || die "--agents-dir requires a value"
      AGENTS_DIR="$2"
      shift 2
      ;;
    --output)
      [[ $# -ge 2 ]] || die "--output requires a value"
      OUTPUT_PATH="$2"
      shift 2
      ;;
    --image-tag)
      [[ $# -ge 2 ]] || die "--image-tag requires a value"
      IMAGE_TAG="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      die "Unknown option '$1'"
      ;;
  esac
done

[[ -n "${OUTPUT_PATH}" ]] || die "--output is required"
[[ -n "${IMAGE_TAG}" ]] || die "--image-tag is required"

ROOT_DIR="$(cd "$(dirname "${CONFIG_PATH}")" && pwd)"
if [[ "${AGENTS_DIR}" != /* ]]; then
  AGENTS_DIR="${ROOT_DIR}/${AGENTS_DIR}"
fi

# shellcheck source=../scripts/common.sh
source "${ROOT_DIR}/scripts/common.sh"

load_config_file
IMAGE_REPOSITORY="${AICAGE_IMAGE_REGISTRY}/${AICAGE_IMAGE_REPOSITORY}"
LOCAL_IMAGE_REPOSITORY="${AICAGE_LOCAL_IMAGE_REPOSITORY}"

BASES_TMPDIR="$(download_bases_archive)"
BASES_DIR="${BASES_TMPDIR}/bases"
BASE_TAG="$(get_base_release_tag)"

tmp_output="$(mktemp)"
yq -n '{"aicage-image": {}, "aicage-image-base": {}, "bases": {}, "agent": {}}' > "${tmp_output}"
yq -i '.["aicage-image"].version = "'"${IMAGE_TAG}"'"' "${tmp_output}"
yq -i '.["aicage-image-base"].version = "'"${BASE_TAG}"'"' "${tmp_output}"

for alias in $(list_base_aliases "${BASES_DIR}"); do
  base_yaml="${BASES_DIR}/${alias}/base.yaml"
  [[ -f "${base_yaml}" ]] || die "Missing base.yaml for ${alias}"
  yq -i \
    '.bases."'"${alias}"'" = load("'"${base_yaml}"'")' \
    "${tmp_output}"
done

for agent_dir in "${AGENTS_DIR}"/*; do
  [[ -d "${agent_dir}" ]] || continue
  agent="$(basename "${agent_dir}")"
  agent_yaml="${agent_dir}/agent.yaml"
  [[ -f "${agent_yaml}" ]] || continue

  if is_agent_field_true "${agent}" build_local; then
    agent_repository="${LOCAL_IMAGE_REPOSITORY}"
  else
    agent_repository="${IMAGE_REPOSITORY}"
  fi

  mapfile -t valid_bases < <(get_bases "${agent}" "${BASES_DIR}")
  bases_list="$(mktemp)"
  for base_alias in "${valid_bases[@]}"; do
    printf -- '%s: %s:%s-%s\n' "${base_alias}" "${agent_repository}" "${agent}" "${base_alias}" \
      >> "${bases_list}"
  done

  agent_tmp="$(mktemp)"
  cp "${agent_yaml}" "${agent_tmp}"
  yq -i '.valid_bases = load("'"${bases_list}"'")' "${agent_tmp}"
  yq -i \
    '.agent."'"${agent}"'" = load("'"${agent_tmp}"'")' \
    "${tmp_output}"

  rm -f "${bases_list}" "${agent_tmp}"
done

mv "${tmp_output}" "${OUTPUT_PATH}"
