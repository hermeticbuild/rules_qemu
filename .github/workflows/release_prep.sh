#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

TAG=$1
PREFIX="rules_qemu-${TAG:1}"
ARCHIVE="rules_qemu-$TAG.tar.gz"

git archive --format=tar --prefix="${PREFIX}/" "${TAG}" | gzip > "${ARCHIVE}"
SHA=$(shasum -a 256 "${ARCHIVE}" | awk '{print $1}')

cat << EOF
## Using Bzlmod with Bazel 7.7 or greater

Add to your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "rules_qemu", version = "${TAG:1}")

qemu = use_extension("@rules_qemu//qemu/extension:qemu.bzl", "qemu")
use_repo(qemu, "qemu_user_toolchains")

register_toolchains("@qemu_user_toolchains//:all")
\`\`\`

## Using an archive override

\`\`\`starlark
archive_override(
    module_name = "rules_qemu",
    integrity = "",
    strip_prefix = "${PREFIX}",
    urls = ["https://github.com/hermeticbuild/rules_qemu/releases/download/${TAG}/${ARCHIVE}"],
)
\`\`\`

SHA256: \`${SHA}\`
EOF
