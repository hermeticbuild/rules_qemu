"""Helpers for declaring QEMU user-mode toolchains."""

load("//qemu:qemu_system_toolchain.bzl", "qemu_system_toolchain")
load("//qemu:qemu_toolchain.bzl", "qemu_toolchain")

EXEC_PLATFORM_TO_REPO_ARCH = {
    ("linux", "x86_64"): "amd64",
    ("linux", "aarch64"): "arm64",
}

TARGET_PLATFORM_TO_QEMU_ARCH = {
    ("linux", "aarch64"): "aarch64",
    ("linux", "arm"): "arm",
    ("linux", "armv7"): "arm",
    ("linux", "i386"): "i386",
    ("linux", "mips64"): "mips64",
    ("linux", "ppc"): "ppc",
    ("linux", "ppc32"): "ppc",
    ("linux", "ppc64le"): "ppc64le",
    ("linux", "riscv32"): "riscv32",
    ("linux", "riscv64"): "riscv64",
    ("linux", "s390x"): "s390x",
    ("linux", "x86_32"): "i386",
    ("linux", "x86_64"): "x86_64",
}

TARGET_PLATFORM_TO_QEMU_SYSTEM = {
    ("linux", "aarch64"): struct(
        binary = "qemu-system-aarch64",
        machine = "virt",
        system_target = "aarch64-softmmu",
    ),
    ("linux", "arm"): struct(
        binary = "qemu-system-arm",
        machine = "virt",
        system_target = "arm-softmmu",
    ),
    ("linux", "armv7"): struct(
        binary = "qemu-system-arm",
        machine = "virt",
        system_target = "arm-softmmu",
    ),
    ("linux", "i386"): struct(
        binary = "qemu-system-i386",
        machine = "q35",
        system_target = "i386-softmmu",
    ),
    ("linux", "mips64"): struct(
        binary = "qemu-system-mips64",
        machine = "malta",
        system_target = "mips64-softmmu",
    ),
    ("linux", "ppc"): struct(
        binary = "qemu-system-ppc",
        machine = "g3beige",
        system_target = "ppc-softmmu",
    ),
    ("linux", "ppc32"): struct(
        binary = "qemu-system-ppc",
        machine = "g3beige",
        system_target = "ppc-softmmu",
    ),
    ("linux", "ppc64le"): struct(
        binary = "qemu-system-ppc64",
        machine = "pseries",
        system_target = "ppc64-softmmu",
    ),
    ("linux", "riscv32"): struct(
        binary = "qemu-system-riscv32",
        machine = "virt",
        system_target = "riscv32-softmmu",
    ),
    ("linux", "riscv64"): struct(
        binary = "qemu-system-riscv64",
        machine = "virt",
        system_target = "riscv64-softmmu",
    ),
    ("linux", "s390x"): struct(
        binary = "qemu-system-s390x",
        machine = "s390-ccw-virtio",
        system_target = "s390x-softmmu",
    ),
    ("linux", "x86_32"): struct(
        binary = "qemu-system-i386",
        machine = "q35",
        system_target = "i386-softmmu",
    ),
    ("linux", "x86_64"): struct(
        binary = "qemu-system-x86_64",
        machine = "q35",
        system_target = "x86_64-softmmu",
    ),
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
                toolchain = name + "_impl",
                toolchain_type = "@rules_qemu//qemu:toolchain_type",
            )

# buildifier: disable=unnamed-macro
def declare_system_toolchains(*, exec_platforms, target_platforms):
    """Declares QEMU system-mode toolchains for exec and target platform pairs.

    Args:
        exec_platforms: Iterable of `(os, cpu)` pairs for the execution platform.
        target_platforms: Iterable of `(os, cpu)` pairs for emulated target platforms.
    """

    for exec_platform in exec_platforms:
        exec_os, exec_cpu = exec_platform
        repo_arch = EXEC_PLATFORM_TO_REPO_ARCH[exec_platform]

        for target_platform in target_platforms:
            target_os, target_cpu = target_platform
            qemu_system = TARGET_PLATFORM_TO_QEMU_SYSTEM[target_platform]
            name = "qemu_system_{}_{}_on_{}_{}".format(target_os, target_cpu, exec_os, exec_cpu)
            repo_system_target = qemu_system.system_target.replace("-", "_")

            qemu_system_toolchain(
                name = name + "_impl",
                machine = qemu_system.machine,
                qemu_img = "@qemu_img_prebuilt_linux_{}//:qemu-img".format(repo_arch),
                qemu_system = "@qemu_system_bin_prebuilt_linux_{}_{}//:{}".format(repo_arch, repo_system_target, qemu_system.binary),
                system_data = "@qemu_system_data_prebuilt_linux_{}//:qemu-system-data".format(repo_arch),
                system_data_anchor = "@qemu_system_data_prebuilt_linux_{}//:qemu-system-data".format(repo_arch),
                system_target = qemu_system.system_target,
                target_arch = target_cpu,
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
                toolchain = name + "_impl",
                toolchain_type = "@rules_qemu//qemu:system_toolchain_type",
            )
