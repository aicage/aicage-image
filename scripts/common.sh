#!/usr/bin/env bash
set -euo pipefail

TOOL_DEFINITIONS_DIR="${ROOT_DIR}/tools"

_die() {
  if command -v die >/dev/null 2>&1; then
    die "$@"
  else
    echo "[common] $*" >&2
    exit 1
  fi
}

load_config_file() {
  local config_file="${ROOT_DIR}/config.yaml"
  [[ -f "${config_file}" ]] || _die "Config file not found: ${config_file}"

  while IFS=$'\t' read -r key value; do
    [[ -z "${key}" ]] && continue
    if [[ -z ${!key+x} ]]; then
      export "${key}=${value}"
    fi
  done < <(yq -er 'to_entries[] | [.key, (.value // "")] | @tsv' "${config_file}")
}

discover_base_aliases() {
  local url="https://hub.docker.com/v2/repositories/${AICAGE_IMAGE_BASE_REPOSITORY}/tags?page_size=100"
  local json next
  while [[ -n "${url}" ]]; do
    json="$(curl -fsSL "${url}")" || _die "Failed to query Docker Hub for ${AICAGE_IMAGE_BASE_REPOSITORY}"
    jq -r '.results[].name | select(test("-latest$")) | sub("(-amd64|-arm64)?-latest$"; "")' <<< "${json}"
    next="$(jq -r '.next // empty' <<< "${json}")"
    url="${next}"
  done | sort -u
}

get_tool_field() {
  local tool="$1"
  local field="$2"
  local tool_dir="${TOOL_DEFINITIONS_DIR}/${tool}"
  local definition_file="${tool_dir}/tool.yaml"

  [[ -d "${tool_dir}" ]] || _die "Tool '${tool}' not found under ${TOOL_DEFINITIONS_DIR}"
  [[ -f "${definition_file}" ]] || _die "Missing tool.yaml for '${tool}'"

  local value
  value="$(yq -er ".${field}" "${definition_file}")" || _die "Failed to read ${field} from ${definition_file}"
  [[ -n "${value}" && "${value}" != "null" ]] || _die "${field} missing in ${definition_file}"
  printf '%s\n' "${value}"
}
