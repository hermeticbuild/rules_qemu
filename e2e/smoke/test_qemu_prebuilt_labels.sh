#!/usr/bin/env bash

# Consumes the public @rules_qemu//qemu prebuilt labels the way a downstream
# test harness does: plain runfiles paths handed to the test as environment
# variables, without going through toolchain resolution.

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

expect_version() {
  local binary="$1"
  local expected="$2"
  local actual

  actual="$("${binary}" --version | head -n 1)"
  if [[ "${actual}" != "${expected}"* ]]; then
    echo "Expected '${binary}' to report '${expected}...', got '${actual}'" >&2
    exit 1
  fi
}

qemu_img="$(resolve_runfile "${QEMU_IMG}")"
expect_version "${qemu_img}" "qemu-img version"
"${qemu_img}" create -f qcow2 "${TEST_TMPDIR}/disk.qcow2" 1M >/dev/null

qemu_system="$(resolve_runfile "${QEMU_SYSTEM_X86_64}")"
expect_version "${qemu_system}" "QEMU emulator version"

# qemu-system-data is a directory artifact, so check that the tree survives
# being aliased and still holds the firmware blobs qemu-system needs from -L.
qemu_system_data="$(resolve_runfile "${QEMU_SYSTEM_DATA}")"
if [[ ! -d "${qemu_system_data}" ]]; then
  echo "Expected '${qemu_system_data}' to be the share/qemu directory" >&2
  exit 1
fi

if [[ ! -f "${qemu_system_data}/bios-256k.bin" ]]; then
  echo "Expected 'bios-256k.bin' in '${qemu_system_data}'" >&2
  exit 1
fi

"${qemu_system}" -L "${qemu_system_data}" -machine help >/dev/null
