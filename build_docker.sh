#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

image="${IMAGE:-rules-qemu-ubuntu}"
bazel_version="$(tr -d '[:space:]' < "${script_dir}/.bazelversion")"

case "$(uname -m)" in
  arm64 | aarch64)
    default_platform="linux/arm64"
    ;;
  x86_64 | amd64)
    default_platform="linux/amd64"
    ;;
  *)
    default_platform=""
    ;;
esac

platform="${DOCKER_PLATFORM:-${default_platform}}"
platform_args=()
if [[ -n "${platform}" ]]; then
  platform_args+=(--platform="${platform}")
fi

docker build \
  "${platform_args[@]}" \
  --build-arg "BAZEL_VERSION=${bazel_version}" \
  -t "${image}" \
  "${script_dir}"

docker_run_args=()
if [[ -t 0 && -t 1 ]]; then
  docker_run_args+=("-it")
fi

if [[ -n "${CONTAINER:-}" ]]; then
  docker_run_args+=(--name "${CONTAINER}")
fi

docker run "${docker_run_args[@]}" \
  --rm \
  "${platform_args[@]}" \
  --shm-size=4G \
  --mount "type=bind,src=${script_dir},dst=/rules_qemu" \
  --mount "type=volume,src=rules-qemu-bazel-cache,dst=/home/fakeuser/.cache/bazel" \
  "${image}" \
  "$@"
