"""Smoke test helper for QEMU system-mode toolchains."""

load("@rules_python//python:py_test.bzl", "py_test")

_QEMU_SYSTEM_TOOLCHAIN_TYPE = Label("@rules_qemu//qemu:exec_toolchain_type")

def _qemu_system_target_impl(_ctx):
    return []

qemu_system_target = rule(
    implementation = _qemu_system_target_impl,
    build_setting = config.string(flag = True),
)

def _runfiles_path(ctx, file):
    if file.short_path.startswith("../"):
        return file.short_path[3:]
    return "{}/{}".format(ctx.workspace_name, file.short_path)

def _qemu_system_qmp_smoke_config_impl(ctx):
    toolchain = ctx.toolchains[_QEMU_SYSTEM_TOOLCHAIN_TYPE]
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
    toolchains = [_QEMU_SYSTEM_TOOLCHAIN_TYPE],
)

def _qemu_system_smoke_test(name, *, script, **kwargs):
    config_name = name + "_config"
    config_kwargs = {}
    if "target_compatible_with" in kwargs:
        config_kwargs["target_compatible_with"] = kwargs["target_compatible_with"]
    deps = kwargs.pop("deps", [])

    _qemu_system_qmp_smoke_config(
        name = config_name,
        testonly = True,
        **config_kwargs
    )

    py_test(
        name = name,
        srcs = [script],
        args = ["$(rlocationpath :{})".format(config_name)],
        config_settings = {
            "@rules_python//python/config_settings:bootstrap_impl": "script",
        },
        data = [":{}".format(config_name)],
        deps = deps + ["@rules_python//python/runfiles"],
        main = script,
        python_version = "3.12",
        **kwargs
    )

def qemu_system_qmp_smoke_test(name, **kwargs):
    _qemu_system_smoke_test(
        name = name,
        script = "system_qmp_smoke.py",
        **kwargs
    )

def qemu_system_x86_boot_smoke_test(name, **kwargs):
    _qemu_system_smoke_test(
        name = name,
        script = "system_x86_boot_smoke.py",
        **kwargs
    )
