"""Helpers for declaring QEMU toolchains."""

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

SYSTEM_TARGET_TO_QEMU_SYSTEM = {
    "aarch64-softmmu": struct(
        binary = "qemu-system-aarch64",
        machine = "virt",
        target_arch = "aarch64",
    ),
    "arm-softmmu": struct(
        binary = "qemu-system-arm",
        machine = "virt",
        target_arch = "arm",
    ),
    "i386-softmmu": struct(
        binary = "qemu-system-i386",
        machine = "q35",
        target_arch = "i386",
    ),
    "mips64-softmmu": struct(
        binary = "qemu-system-mips64",
        machine = "malta",
        target_arch = "mips64",
    ),
    "ppc-softmmu": struct(
        binary = "qemu-system-ppc",
        machine = "g3beige",
        target_arch = "ppc",
    ),
    "ppc64-softmmu": struct(
        binary = "qemu-system-ppc64",
        machine = "pseries",
        target_arch = "ppc64",
    ),
    "riscv32-softmmu": struct(
        binary = "qemu-system-riscv32",
        machine = "virt",
        target_arch = "riscv32",
    ),
    "riscv64-softmmu": struct(
        binary = "qemu-system-riscv64",
        machine = "virt",
        target_arch = "riscv64",
    ),
    "s390x-softmmu": struct(
        binary = "qemu-system-s390x",
        machine = "s390-ccw-virtio",
        target_arch = "s390x",
    ),
    "x86_64-softmmu": struct(
        binary = "qemu-system-x86_64",
        machine = "q35",
        target_arch = "x86_64",
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
def declare_system_toolchains(*, exec_platforms, system_toolchains):
    """Declares QEMU system-mode toolchains for exec platforms.

    Args:
        exec_platforms: Iterable of `(os, cpu)` pairs for the execution platform.
        system_toolchains: Iterable of dictionaries with `name`,
            `system_target`, and `target_settings` fields. `machine` and
            `target_arch` may optionally override rules_qemu metadata.
    """

    for system_toolchain in system_toolchains:
        if system_toolchain["system_target"] not in SYSTEM_TARGET_TO_QEMU_SYSTEM:
            fail("unsupported QEMU system target: {}".format(system_toolchain["system_target"]))
        if not system_toolchain["target_settings"]:
            fail("QEMU system target {} must declare at least one target_setting".format(system_toolchain["system_target"]))

    for exec_platform in exec_platforms:
        exec_os, exec_cpu = exec_platform
        repo_arch = EXEC_PLATFORM_TO_REPO_ARCH[exec_platform]

        for system_toolchain in system_toolchains:
            system_target = system_toolchain["system_target"]
            qemu_system = SYSTEM_TARGET_TO_QEMU_SYSTEM[system_target]
            name = "qemu_system_{}_on_{}_{}".format(system_toolchain["name"], exec_os, exec_cpu)
            repo_system_target = system_target.replace("-", "_")
            machine = system_toolchain["machine"] or qemu_system.machine
            target_arch = system_toolchain["target_arch"] or qemu_system.target_arch

            qemu_system_toolchain(
                name = name + "_impl",
                machine = machine,
                qemu_img = "@qemu_img_prebuilt_linux_{}//:qemu-img".format(repo_arch),
                qemu_system = "@qemu_system_bin_prebuilt_linux_{}_{}//:{}".format(repo_arch, repo_system_target, qemu_system.binary),
                system_data = "@qemu_system_data_prebuilt_linux_{}//:qemu-system-data".format(repo_arch),
                system_data_anchor = "@qemu_system_data_prebuilt_linux_{}//:qemu-system-data".format(repo_arch),
                system_target = system_target,
                target_arch = target_arch,
            )

            native.toolchain(
                name = name,
                exec_compatible_with = [
                    "@platforms//os:{}".format(exec_os),
                    "@platforms//cpu:{}".format(exec_cpu),
                ],
                target_settings = system_toolchain["target_settings"],
                toolchain = name + "_impl",
                toolchain_type = "@rules_qemu//qemu:system_toolchain_type",
            )
