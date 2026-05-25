"""Toolchain rule for QEMU system-mode emulator binaries."""

_QEMU_SYSTEM_TOOLCHAIN_TYPE = Label("//qemu:system_toolchain_type")
_QEMU_SYSTEM_GUEST_PLATFORM = "//qemu:system_guest_platform"

QemuSystemToolchainInfo = provider(
    doc = "QEMU system-mode emulator toolchain.",
    fields = {
        "accel": "Default QEMU accelerator hint.",
        "machine": "Default QEMU machine type hint.",
        "qemu_img": "The qemu-img executable file.",
        "qemu_system": "The qemu-system-* executable file.",
        "system_data_anchor": "The share/qemu directory used as the QEMU data directory.",
        "system_data_files": "Depset containing the QEMU system runtime data directory.",
        "system_target": "The QEMU softmmu target name.",
        "target_arch": "The Bazel target CPU name.",
    },
)

def _qemu_system_toolchain_impl(ctx):
    system_data_files = depset(ctx.files.system_data)
    qemu_system_info = QemuSystemToolchainInfo(
        accel = ctx.attr.accel,
        machine = ctx.attr.machine,
        qemu_img = ctx.file.qemu_img,
        qemu_system = ctx.file.qemu_system,
        system_data_anchor = ctx.files.system_data_anchor[0],
        system_data_files = system_data_files,
        system_target = ctx.attr.system_target,
        target_arch = ctx.attr.target_arch,
    )

    return [
        platform_common.ToolchainInfo(
            accel = qemu_system_info.accel,
            machine = qemu_system_info.machine,
            qemu_img = qemu_system_info.qemu_img,
            qemu_system = qemu_system_info.qemu_system,
            qemu_system_info = qemu_system_info,
            system_data_anchor = qemu_system_info.system_data_anchor,
            system_data_files = qemu_system_info.system_data_files,
            system_target = qemu_system_info.system_target,
            target_arch = qemu_system_info.target_arch,
        ),
        qemu_system_info,
    ]

qemu_system_toolchain = rule(
    implementation = _qemu_system_toolchain_impl,
    attrs = {
        "accel": attr.string(
            default = "tcg",
            doc = "Default QEMU accelerator hint.",
        ),
        "machine": attr.string(
            mandatory = True,
            doc = "Default QEMU machine type hint.",
        ),
        "qemu_img": attr.label(
            allow_single_file = True,
            cfg = "exec",
            mandatory = True,
        ),
        "qemu_system": attr.label(
            allow_single_file = True,
            cfg = "exec",
            mandatory = True,
        ),
        "system_data": attr.label(
            allow_files = True,
            cfg = "exec",
            mandatory = True,
        ),
        "system_data_anchor": attr.label(
            allow_files = True,
            cfg = "exec",
            mandatory = True,
        ),
        "system_target": attr.string(
            mandatory = True,
            doc = "QEMU softmmu target name.",
        ),
        "target_arch": attr.string(
            mandatory = True,
            doc = "Bazel target CPU name.",
        ),
    },
    doc = "Defines a QEMU system-mode toolchain with qemu-system, qemu-img, and share/qemu data.",
)

def qemu_system_guest_platform_name(os, cpu):
    return "system_guest_{}_{}".format(os, cpu)

def qemu_system_guest_config_setting_name(os, cpu):
    return "system_guest_is_{}_{}".format(os, cpu)

# buildifier: disable=unnamed-macro
def declare_qemu_system_guest_platforms(*, target_platforms):
    """Declares QEMU system guest platform settings.

    These labels represent the platform QEMU should emulate. They are separate
    from Bazel's target platform so a host-configured rule can still request a
    QEMU binary for a specific guest machine.

    Args:
        target_platforms: Iterable of `(os, cpu)` guest platform pairs.
    """

    native.filegroup(
        name = "system_guest_unset",
        visibility = ["//visibility:public"],
    )

    native.label_setting(
        name = "system_guest_platform",
        build_setting_default = ":system_guest_unset",
        visibility = ["//visibility:public"],
    )

    for os, cpu in target_platforms:
        guest_platform = qemu_system_guest_platform_name(os, cpu)
        native.filegroup(
            name = guest_platform,
            visibility = ["//visibility:public"],
        )

        native.config_setting(
            name = qemu_system_guest_config_setting_name(os, cpu),
            flag_values = {
                ":system_guest_platform": ":{}".format(guest_platform),
            },
            visibility = ["//visibility:public"],
        )

def _qemu_system_guest_transition_impl(_settings, attr):
    return {
        _QEMU_SYSTEM_GUEST_PLATFORM: attr.guest_platform,
    }

_qemu_system_guest_transition = transition(
    implementation = _qemu_system_guest_transition_impl,
    inputs = [],
    outputs = [_QEMU_SYSTEM_GUEST_PLATFORM],
)

def _qemu_system_resolved_toolchain_impl(ctx):
    qemu_system_info = ctx.toolchains[_QEMU_SYSTEM_TOOLCHAIN_TYPE].qemu_system_info
    return [
        DefaultInfo(
            files = depset(
                [
                    qemu_system_info.qemu_img,
                    qemu_system_info.qemu_system,
                    qemu_system_info.system_data_anchor,
                ],
                transitive = [qemu_system_info.system_data_files],
            ),
            runfiles = ctx.runfiles(
                files = [
                    qemu_system_info.qemu_img,
                    qemu_system_info.qemu_system,
                    qemu_system_info.system_data_anchor,
                ],
                transitive_files = qemu_system_info.system_data_files,
            ),
        ),
        qemu_system_info,
    ]

qemu_system_resolved_toolchain = rule(
    implementation = _qemu_system_resolved_toolchain_impl,
    attrs = {
        "guest_platform": attr.label(
            mandatory = True,
            doc = "A @rules_qemu//qemu:system_guest_* label selecting the QEMU guest platform.",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
    cfg = _qemu_system_guest_transition,
    doc = "Resolves a QEMU system-mode toolchain for an explicit guest platform.",
    toolchains = [_QEMU_SYSTEM_TOOLCHAIN_TYPE],
)
