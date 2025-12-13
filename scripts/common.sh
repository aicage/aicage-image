#!/usr/bin/env bash
set -euo pipefail

_die() {
  if command -v die >/dev/null 2>&1; then
    die "$@"
  else
    echo "[common] $*" >&2
    exit 1
  fi
}

load_env_file() {
  local env_file="${ROOT_DIR}/.env"

  # The read condition handles files that omit a trailing newline.
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue
    if [[ "${line}" =~ ^([^=]+)=(.*)$ ]]; then
      local key="${BASH_REMATCH[1]}"
      local value="${BASH_REMATCH[2]}"
      if [[ -z ${!key+x} ]]; then
        if [[ "${value}" =~ ^\".*\"$ ]]; then
          value="${value:1:${#value}-2}"
        fi
        export "${key}=${value}"
      fi
    fi
  done < "${env_file}"
}

discover_base_aliases() {
  local url="https://hub.docker.com/v2/repositories/${AICAGE_BASE_REPOSITORY}/tags?page_size=100"
  local json next

  while [[ -n "${url}" ]]; do
    json="$(curl -fsSL "${url}")" || _die "Failed to query Docker Hub for ${AICAGE_BASE_REPOSITORY}"
    jq -r '.results[].name | select(test("-latest$")) | sub("-latest$"; "")' <<< "${json}"
    next="$(jq -r '.next // empty' <<< "${json}")"
    url="${next}"
  done
}
