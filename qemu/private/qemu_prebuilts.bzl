"""Label metadata for the public QEMU prebuilt aliases.

The module extension downloads one repository per prebuilt artifact and
execution architecture. Those repository names encode the prebuilt layout and
are implementation details, so the extension also generates a `qemu_prebuilts`
hub repository holding one architecture-selecting `alias` per prebuilt, which
`@rules_qemu//qemu` re-exports.

This file is the single source of truth for that label set: both the generated
hub repository and the `@rules_qemu//qemu` re-exports are derived from it.
"""

load(
    "//qemu:declare_toolchains.bzl",
    "EXEC_PLATFORM_TO_REPO_ARCH",
    "SYSTEM_TARGET_TO_QEMU_SYSTEM",
    "TARGET_PLATFORM_TO_QEMU_ARCH",
)

def qemu_prebuilt_exec_platforms():
    """Returns the execution platforms the QEMU prebuilts are published for.

    Returns:
        A list of structs sorted by `config_setting`, with fields:
            `config_setting`: name of the `config_setting` declared in the
                generated hub repository, such as `linux_amd64`.
            `constraint_values`: sorted platform constraint labels that select
                this execution platform.
            `exec_arch`: the architecture as spelled in the prebuilt repository
                names, such as `amd64`.
    """

    exec_platforms = []
    for (exec_os, exec_cpu), exec_arch in EXEC_PLATFORM_TO_REPO_ARCH.items():
        exec_platforms.append(struct(
            config_setting = "{}_{}".format(exec_os, exec_arch),
            constraint_values = [
                "@platforms//cpu:{}".format(exec_cpu),
                "@platforms//os:{}".format(exec_os),
            ],
            exec_arch = exec_arch,
        ))

    return sorted(exec_platforms, key = lambda exec_platform: exec_platform.config_setting)

def qemu_prebuilt_aliases():
    """Returns the public labels exposed for the QEMU prebuilt binaries.

    Returns:
        A list of structs sorted by `name`, with fields:
            `name`: the public label name, which matches the target name inside
                the backing prebuilt repository, such as `qemu-img`.
            `repos`: dict mapping each `exec_arch` to the prebuilt repository
                that provides `name` for that execution architecture.
    """

    exec_arches = [exec_platform.exec_arch for exec_platform in qemu_prebuilt_exec_platforms()]

    aliases = [
        struct(
            name = "qemu-img",
            repos = {
                exec_arch: "qemu_img_prebuilt_linux_{}".format(exec_arch)
                for exec_arch in exec_arches
            },
        ),
        struct(
            name = "qemu-system-data",
            repos = {
                exec_arch: "qemu_system_data_prebuilt_linux_{}".format(exec_arch)
                for exec_arch in exec_arches
            },
        ),
    ]

    for system_target, qemu_system in SYSTEM_TARGET_TO_QEMU_SYSTEM.items():
        repo_system_target = system_target.replace("-", "_")
        aliases.append(struct(
            name = qemu_system.binary,
            repos = {
                exec_arch: "qemu_system_bin_prebuilt_linux_{}_{}".format(exec_arch, repo_system_target)
                for exec_arch in exec_arches
            },
        ))

    for qemu_arch in sorted({qemu_arch: None for qemu_arch in TARGET_PLATFORM_TO_QEMU_ARCH.values()}):
        aliases.append(struct(
            name = "qemu-{}".format(qemu_arch),
            repos = {
                exec_arch: "qemu_user_prebuilt_linux_{}_{}".format(exec_arch, qemu_arch)
                for exec_arch in exec_arches
            },
        ))

    return sorted(aliases, key = lambda alias: alias.name)
