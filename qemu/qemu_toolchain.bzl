"""Toolchain rule for QEMU user-mode emulator binaries."""

QemuUserToolchainInfo = provider(
    doc = "QEMU user-mode emulator toolchain.",
    fields = {
        "qemu": "The QEMU executable file.",
    },
)

def _qemu_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            qemu = ctx.file.qemu,
        ),
        QemuUserToolchainInfo(
            qemu = ctx.file.qemu,
        ),
    ]

qemu_toolchain = rule(
    implementation = _qemu_toolchain_impl,
    attrs = {
        "qemu": attr.label(
            allow_single_file = True,
            cfg = "exec",
            mandatory = True,
        ),
    },
)
