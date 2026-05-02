_TOOLCHAINS_BUILD = """\
load("@rules_qemu//qemu:declare_toolchains.bzl", "declare_toolchains")

package(default_visibility = ["//visibility:public"])

EXEC_PLATFORMS = [
    ("linux", "x86_64"),
    ("linux", "aarch64"),
]

TARGET_PLATFORMS = [
    ("linux", "aarch64"),
    ("linux", "arm"),
    ("linux", "i386"),
    ("linux", "mips64"),
    ("linux", "ppc"),
    ("linux", "ppc64le"),
    ("linux", "riscv32"),
    ("linux", "riscv64"),
    ("linux", "s390x"),
    ("linux", "x86_32"),
    ("linux", "x86_64"),
]

declare_toolchains(
    exec_platforms = EXEC_PLATFORMS,
    target_platforms = TARGET_PLATFORMS,
)
"""

def _qemu_toolchains_repository_impl(rctx):
    rctx.file("BUILD.bazel", _TOOLCHAINS_BUILD)
    return rctx.repo_metadata(reproducible = True)

qemu_toolchains_repository = repository_rule(
    implementation = _qemu_toolchains_repository_impl,
)