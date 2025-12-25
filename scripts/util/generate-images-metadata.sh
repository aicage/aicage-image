#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/util/generate-images-metadata.sh --output <path> --image-tag <tag> [options]

Options:
  --config <path>     Path to config.yaml (default: config.yaml)
  --tools-dir <path>  Path to tools directory (default: tools)
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
TOOLS_DIR="${ROOT_DIR}/tools"
OUTPUT_PATH=""
IMAGE_TAG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      [[ $# -ge 2 ]] || die "--config requires a value"
      CONFIG_PATH="$2"
      shift 2
      ;;
    --tools-dir)
      [[ $# -ge 2 ]] || die "--tools-dir requires a value"
      TOOLS_DIR="$2"
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
if [[ "${TOOLS_DIR}" != /* ]]; then
  TOOLS_DIR="${ROOT_DIR}/${TOOLS_DIR}"
fi

# shellcheck source=../scripts/common.sh
source "${ROOT_DIR}/scripts/common.sh"

load_config_file

BASES_TMPDIR="$(download_bases_archive)"
BASES_DIR="${BASES_TMPDIR}/bases"
BASE_TAG="$(get_base_release_tag)"

tmp_output="$(mktemp)"
yq -n '{"aicage-image": {}, "aicage-image-base": {}, "bases": {}, "tool": {}}' > "${tmp_output}"
yq -i '.["aicage-image"].version = "'"${IMAGE_TAG}"'"' "${tmp_output}"
yq -i '.["aicage-image-base"].version = "'"${BASE_TAG}"'"' "${tmp_output}"

for alias in $(list_base_aliases "${BASES_DIR}"); do
  base_yaml="${BASES_DIR}/${alias}/base.yaml"
  [[ -f "${base_yaml}" ]] || die "Missing base.yaml for ${alias}"
  yq -i \
    '.bases."'"${alias}"'" = load("'"${base_yaml}"'")' \
    "${tmp_output}"
done

for tool_dir in "${TOOLS_DIR}"/*; do
  [[ -d "${tool_dir}" ]] || continue
  tool="$(basename "${tool_dir}")"
  tool_yaml="${tool_dir}/tool.yaml"
  [[ -f "${tool_yaml}" ]] || continue

  mapfile -t valid_bases < <(get_bases "${tool}" "${BASES_DIR}")
  bases_list="$(mktemp)"
  for base_alias in "${valid_bases[@]}"; do
    printf -- '- %s\n' "${base_alias}" >> "${bases_list}"
  done

  tool_tmp="$(mktemp)"
  cp "${tool_yaml}" "${tool_tmp}"
  yq -i '.valid_bases = load("'"${bases_list}"'")' "${tool_tmp}"
  yq -i \
    '.tool."'"${tool}"'" = load("'"${tool_tmp}"'")' \
    "${tmp_output}"

  rm -f "${bases_list}" "${tool_tmp}"
done

mv "${tmp_output}" "${OUTPUT_PATH}"
