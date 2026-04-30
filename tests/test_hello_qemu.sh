#!/usr/bin/env bash

set -euo pipefail

resolve_runfile() {
  local path="$1"

  if [[ -n "${RUNFILES_DIR:-}" && -e "${RUNFILES_DIR}/${path}" ]]; then
    printf '%s\n' "${RUNFILES_DIR}/${path}"
    return
  fi

  if [[ -n "${RUNFILES_MANIFEST_FILE:-}" ]]; then
    local resolved
    resolved="$(awk -v path="${path}" '$1 == path {print substr($0, length($1) + 2); exit}' "${RUNFILES_MANIFEST_FILE}")"
    if [[ -n "${resolved}" ]]; then
      printf '%s\n' "${resolved}"
      return
    fi
  fi

  if [[ -e "${path}" ]]; then
    printf '%s\n' "${path}"
    return
  fi

  echo "Unable to resolve runfile: ${path}" >&2
  return 1
}

actual="$("$(resolve_runfile "${BINARY}")")"

if [[ "${actual}" != "${EXPECTED_OUTPUT}" ]]; then
  echo "Expected '${EXPECTED_OUTPUT}', got '${actual}'" >&2
  exit 1
fi
