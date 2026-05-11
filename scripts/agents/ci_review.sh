#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-appstore}"
POLICY_FILE="scripts/agents/policies/${PROFILE}.policy"

if [[ ! -f "${POLICY_FILE}" ]]; then
  echo "Policy file not found: ${POLICY_FILE}"
  exit 2
fi

# shellcheck source=/dev/null
source "${POLICY_FILE}"

echo "Running agent checks with profile: ${PROFILE_NAME}"
echo "Policy: ${POLICY_FILE}"

FAIL=0

scan_with_pattern() {
  local pattern="$1"
  local mode="$2"
  local output

  set +e
  output=$(rg -n --hidden --glob "${SCAN_GLOBS}" "${pattern}" . 2>/dev/null)
  local status=$?
  set -e

  if [[ ${status} -eq 0 ]]; then
    if [[ "${mode}" == "deny" ]]; then
      echo "DENY matched pattern: ${pattern}"
      echo "${output}"
      FAIL=1
    else
      echo "WARN matched pattern: ${pattern}"
      echo "${output}"
    fi
  fi
}

IFS='|' read -r -a DENIES <<< "${DENY_PATTERNS}"
for p in "${DENIES[@]}"; do
  [[ -z "${p}" ]] && continue
  scan_with_pattern "${p}" "deny"
done

IFS='|' read -r -a WARNS <<< "${WARN_PATTERNS}"
for p in "${WARNS[@]}"; do
  [[ -z "${p}" ]] && continue
  scan_with_pattern "${p}" "warn"
done

if [[ ${FAIL} -ne 0 ]]; then
  echo "Agent review failed."
  exit 1
fi

echo "Agent review passed."
