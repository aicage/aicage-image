#!/usr/bin/env bats

setup() {
  ROOT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"
  # shellcheck source=../../scripts/common.sh
  source "${ROOT_DIR}/scripts/common.sh"
  load_config_file
  EXPECTED_AGENT_PATH="$(get_agent_field "${AGENT}" agent_path)"
  EXPECTED_AGENT_FULL_NAME="$(get_agent_field "${AGENT}" agent_full_name)"
  EXPECTED_AGENT_HOMEPAGE="$(get_agent_field "${AGENT}" agent_homepage)"
}

@test "image labels include base metadata" {
  run docker image inspect \
    --format '{{ index .Config.Labels "org.aicage.agent.agent_path" }}' \
    "${AICAGE_IMAGE}"
  [ "$status" -eq 0 ]
  [ "$output" = "${EXPECTED_AGENT_PATH}" ]

  run docker image inspect \
    --format '{{ index .Config.Labels "org.aicage.agent.agent_full_name" }}' \
    "${AICAGE_IMAGE}"
  [ "$status" -eq 0 ]
  [ "$output" = "${EXPECTED_AGENT_FULL_NAME}" ]

  run docker image inspect \
    --format '{{ index .Config.Labels "org.aicage.agent.agent_homepage" }}' \
    "${AICAGE_IMAGE}"
  [ "$status" -eq 0 ]
  [ "$output" = "${EXPECTED_AGENT_HOMEPAGE}" ]

  run docker image inspect \
    --format '{{ index .Config.Labels "org.opencontainers.image.description" }}' \
    "${AICAGE_IMAGE}"
  [ "$status" -eq 0 ]
  [ "$output" = "Agent image for ${AGENT}" ]
}
