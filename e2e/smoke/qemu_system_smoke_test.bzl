"""Smoke test helper for QEMU system-mode toolchains."""

load("@rules_python//python:py_test.bzl", "py_test")
load(
    "@rules_qemu//qemu:qemu_system_toolchain.bzl",
    "QemuSystemToolchainInfo",
    "qemu_system_resolved_toolchain",
)

def _runfiles_path(ctx, file):
    if file.short_path.startswith("../"):
        return file.short_path[3:]
    return "{}/{}".format(ctx.workspace_name, file.short_path)

def _qemu_system_qmp_smoke_config_impl(ctx):
    toolchain = ctx.attr.qemu[QemuSystemToolchainInfo]
    config = ctx.actions.declare_file(ctx.label.name + ".json")
    ctx.actions.write(
        output = config,
        content = json.encode_indent({
            "accel": toolchain.accel,
            "machine": toolchain.machine,
            "qemu_img": _runfiles_path(ctx, toolchain.qemu_img),
            "qemu_system": _runfiles_path(ctx, toolchain.qemu_system),
            "system_data_anchor": _runfiles_path(ctx, toolchain.system_data_anchor),
            "system_target": toolchain.system_target,
            "target_arch": toolchain.target_arch,
        }),
    )

    return [
        DefaultInfo(
            files = depset([config]),
            runfiles = ctx.runfiles(
                files = [
                    config,
                    toolchain.qemu_img,
                    toolchain.qemu_system,
                    toolchain.system_data_anchor,
                ],
                transitive_files = toolchain.system_data_files,
            ),
        ),
    ]

_qemu_system_qmp_smoke_config = rule(
    implementation = _qemu_system_qmp_smoke_config_impl,
    attrs = {
        "qemu": attr.label(
            cfg = "exec",
            mandatory = True,
            providers = [QemuSystemToolchainInfo],
        ),
    },
)

def _qemu_system_api_probe_impl(ctx):
    x86_64 = ctx.attr.x86_64[QemuSystemToolchainInfo]
    riscv64 = ctx.attr.riscv64[QemuSystemToolchainInfo]
    expected = {
        "riscv64": struct(
            machine = "virt",
            qemu_system_basename = "qemu-system-riscv64",
            system_target = "riscv64-softmmu",
            target_arch = "riscv64",
        ),
        "x86_64": struct(
            machine = "q35",
            qemu_system_basename = "qemu-system-x86_64",
            system_target = "x86_64-softmmu",
            target_arch = "x86_64",
        ),
    }

    for name, toolchain in {
        "riscv64": riscv64,
        "x86_64": x86_64,
    }.items():
        want = expected[name]
        if toolchain.system_target != want.system_target:
            fail("{} resolved {}, expected {}".format(name, toolchain.system_target, want.system_target))
        if toolchain.target_arch != want.target_arch:
            fail("{} resolved target_arch {}, expected {}".format(name, toolchain.target_arch, want.target_arch))
        if toolchain.machine != want.machine:
            fail("{} resolved machine {}, expected {}".format(name, toolchain.machine, want.machine))
        if toolchain.qemu_system.basename != want.qemu_system_basename:
            fail("{} resolved {}, expected {}".format(name, toolchain.qemu_system.basename, want.qemu_system_basename))

    out = ctx.actions.declare_file(ctx.label.name + ".txt")
    ctx.actions.write(
        output = out,
        content = "{}\n{}\n".format(x86_64.system_target, riscv64.system_target),
    )
    return [DefaultInfo(files = depset([out]))]

_qemu_system_api_probe = rule(
    implementation = _qemu_system_api_probe_impl,
    attrs = {
        "riscv64": attr.label(
            cfg = "exec",
            mandatory = True,
            providers = [QemuSystemToolchainInfo],
        ),
        "x86_64": attr.label(
            cfg = "exec",
            mandatory = True,
            providers = [QemuSystemToolchainInfo],
        ),
    },
)

def qemu_system_api_probe(name, **kwargs):
    qemu_system_resolved_toolchain(
        name = name + "_x86_64_qemu",
        guest_platform = "//:qemu_guest_linux_x86_64",
        testonly = True,
    )

    qemu_system_resolved_toolchain(
        name = name + "_riscv64_qemu",
        guest_platform = "//:qemu_guest_linux_riscv64",
        testonly = True,
    )

    _qemu_system_api_probe(
        name = name,
        riscv64 = ":{}_riscv64_qemu".format(name),
        testonly = True,
        x86_64 = ":{}_x86_64_qemu".format(name),
        **kwargs
    )

def _qemu_system_smoke_test(name, *, guest_platform, script, **kwargs):
    qemu_name = name + "_qemu"
    config_name = name + "_config"

    qemu_system_resolved_toolchain(
        name = qemu_name,
        guest_platform = guest_platform,
        testonly = True,
    )

    _qemu_system_qmp_smoke_config(
        name = config_name,
        qemu = ":{}".format(qemu_name),
        testonly = True,
    )

    py_test(
        name = name,
        srcs = [script],
        args = ["$(rootpath :{})".format(config_name)],
        config_settings = {
            "@rules_python//python/config_settings:bootstrap_impl": "script",
        },
        data = [":{}".format(config_name)],
        main = script,
        python_version = "3.12",
        **kwargs
    )

def qemu_system_qmp_smoke_test(name, guest_platform = "//:qemu_guest_linux_x86_64", **kwargs):
    _qemu_system_smoke_test(
        name = name,
        guest_platform = guest_platform,
        script = "system_qmp_smoke.py",
        **kwargs
    )

def qemu_system_x86_boot_smoke_test(name, guest_platform = "//:qemu_guest_linux_x86_64", **kwargs):
    _qemu_system_smoke_test(
        name = name,
        guest_platform = guest_platform,
        script = "system_x86_boot_smoke.py",
        **kwargs
    )
