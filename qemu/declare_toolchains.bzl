"""Helpers for declaring QEMU user-mode toolchains."""

load("//qemu:qemu_toolchain.bzl", "qemu_toolchain")

EXEC_PLATFORM_TO_REPO_ARCH = {
    ("linux", "x86_64"): "amd64",
    ("linux", "aarch64"): "arm64",
}

TARGET_PLATFORM_TO_QEMU_ARCH = {
    ("linux", "aarch64"): "aarch64",
    ("linux", "arm"): "arm",
    ("linux", "i386"): "i386",
    ("linux", "mips64"): "mips64",
    ("linux", "ppc"): "ppc",
    ("linux", "ppc64le"): "ppc64le",
    ("linux", "riscv32"): "riscv32",
    ("linux", "riscv64"): "riscv64",
    ("linux", "s390x"): "s390x",
    ("linux", "x86_32"): "i386",
    ("linux", "x86_64"): "x86_64",
}

# buildifier: disable=unnamed-macro
def declare_toolchains(*, exec_platforms, target_platforms):
    """Declares QEMU toolchains for exec and target platform pairs.

    Args:
        exec_platforms: Iterable of `(os, cpu)` pairs for the execution platform.
        target_platforms: Iterable of `(os, cpu)` pairs for emulated target platforms.
    """

    for exec_platform in exec_platforms:
        exec_os, exec_cpu = exec_platform
        repo_arch = EXEC_PLATFORM_TO_REPO_ARCH[exec_platform]

        for target_platform in target_platforms:
            target_os, target_cpu = target_platform
            qemu_arch = TARGET_PLATFORM_TO_QEMU_ARCH[target_platform]
            name = "qemu_{}_{}_on_{}_{}".format(target_os, target_cpu, exec_os, exec_cpu)

            qemu_toolchain(
                name = name + "_impl",
                qemu = "@qemu_user_prebuilt_linux_{}_{}//:qemu-{}".format(repo_arch, qemu_arch, qemu_arch),
            )

            native.toolchain(
                name = name,
                exec_compatible_with = [
                    "@platforms//os:{}".format(exec_os),
                    "@platforms//cpu:{}".format(exec_cpu),
                ],
                target_compatible_with = [
                    "@platforms//os:{}".format(target_os),
                    "@platforms//cpu:{}".format(target_cpu),
                ],
                toolchain = ":" + name + "_impl",
                toolchain_type = "@rules_qemu//qemu:toolchain_type",
            )
