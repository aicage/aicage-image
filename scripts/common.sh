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

download_bases_archive() {
  local base_repo="${AICAGE_IMAGE_BASE_REPOSITORY}"
  local url="https://github.com/${base_repo}/releases/latest/download/bases.tar.gz"
  local tmpdir

  tmpdir="$(mktemp -d)" || _die "Failed to create temp dir"

  if ! curl -fsSL "${url}" -o "${tmpdir}/bases.tar.gz"; then
    _die "Failed to download ${url}"
  fi

  if ! tar -xzf "${tmpdir}/bases.tar.gz" -C "${tmpdir}"; then
    _die "Failed to unpack ${tmpdir}/bases.tar.gz"
  fi

  if [[ ! -d "${tmpdir}/bases" ]]; then
    _die "Missing bases directory in ${url}"
  fi

  printf '%s\n' "${tmpdir}"
}

list_base_aliases() {
  local bases_dir="$1"

  [[ -d "${bases_dir}" ]] || _die "Bases directory not found: ${bases_dir}"

  shopt -s nullglob
  for dir in "${bases_dir}"/*/; do
    basename "${dir}"
  done | sort -u
  shopt -u nullglob
}
