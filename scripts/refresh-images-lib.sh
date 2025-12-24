#!/usr/bin/env bash
set -euo pipefail

get_manifest_digest() {
  local image="$1"
  local arch="$2"
  skopeo inspect --raw "docker://${image}" \
    | jq -r --arg arch "${arch}" '.manifests[]? | select(.platform.architecture == $arch) | .digest' \
    | head -n 1
}

get_last_layer() {
  local image="$1"
  local digest="$2"
  skopeo inspect "docker://${image}@${digest}" | jq -r '.Layers[]' | tail -n 1
}

needs_rebuild() {
  local tool="$1"
  local base="$2"
  local version="$3"
  local base_image="${AICAGE_IMAGE_REGISTRY}/${AICAGE_IMAGE_BASE_REPOSITORY}:${base}-latest"
  local final_image="${AICAGE_IMAGE_REGISTRY}/${AICAGE_IMAGE_REPOSITORY}:${tool}-${base}-${version}"

  if ! skopeo inspect "docker://${final_image}" >/dev/null 2>&1; then
    echo "${final_image} is missing"
    return 0
  fi

  for arch in amd64 arm64; do
    local base_digest
    base_digest="$(get_manifest_digest "${base_image}" "${arch}")"
    if [[ -z "${base_digest}" ]]; then
      echo "Missing ${arch} digest for ${base_image}"
      return 0
    fi

    local final_digest
    final_digest="$(get_manifest_digest "${final_image}" "${arch}")"
    if [[ -z "${final_digest}" ]]; then
      echo "Missing ${arch} digest for ${final_image}"
      return 0
    fi

    local base_last_layer
    base_last_layer="$(get_last_layer "${base_image}" "${base_digest}")"
    if [[ -z "${base_last_layer}" ]]; then
      echo "Missing last layer for ${base_image}@${base_digest}"
      return 0
    fi

    if ! skopeo inspect "docker://${final_image}@${final_digest}" \
      | jq -r '.Layers[]' \
      | grep -Fxq "${base_last_layer}"; then
      echo "${final_image}@${final_digest} missing base layer ${base_last_layer} (${arch})"
      return 0
    fi
  done

  return 1
}
