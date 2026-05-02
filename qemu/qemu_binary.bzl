"""Rules for running target binaries through QEMU user-mode emulators."""

load("@bazel_lib//lib:transitions.bzl", "platform_transition_binary")
load("@hermetic_launcher//launcher:lib.bzl", "launcher")

_QEMU_TOOLCHAIN_TYPE = Label("//qemu:toolchain_type")

def _qemu_binary_impl(ctx):
    qemu = ctx.toolchains[_QEMU_TOOLCHAIN_TYPE].qemu
    binary = ctx.attr.binary[DefaultInfo]
    binary_executable = binary.files_to_run.executable

    if not binary_executable:
        fail("qemu_binary requires an executable binary")

    executable = ctx.actions.declare_file(ctx.label.name)
    embedded_args, transformed_args = launcher.args_from_entrypoint(
        executable_file = qemu,
    )
    embedded_args, transformed_args = launcher.append_runfile(
        file = binary_executable,
        embedded_args = embedded_args,
        transformed_args = transformed_args,
    )
    launcher.compile_stub(
        ctx = ctx,
        embedded_args = embedded_args,
        transformed_args = transformed_args,
        output_file = executable,
        cfg = "exec",
    )

    runfiles = ctx.runfiles(files = [
        qemu,
        binary_executable,
    ]).merge(binary.default_runfiles)

    return [
        DefaultInfo(
            files = depset([executable]),
            executable = executable,
            runfiles = runfiles,
        ),
    ]

_qemu_binary = rule(
    implementation = _qemu_binary_impl,
    attrs = {
        "binary": attr.label(
            executable = True,
            cfg = "target",
            mandatory = True,
        ),
    },
    executable = True,
    toolchains = [
        _QEMU_TOOLCHAIN_TYPE,
        "@hermetic_launcher//launcher:finalizer_toolchain_type",
        "@hermetic_launcher//launcher:template_exec_toolchain_type",
    ],
)

def qemu_binary(name, binary, target_platform, testonly = False, **kwargs):
    _qemu_binary(
        name = name + "_raw",
        binary = binary,
        tags = ["manual"],
        testonly = testonly,
    )

    platform_transition_binary(
        name = name,
        binary = name + "_raw",
        target_platform = target_platform,
        testonly = testonly,
        **kwargs
    )
