# rules_qemu

`rules_qemu` provides Bazel rules and toolchains for running target binaries
with hermetic QEMU binaries.

The goal of this project is to provide fully hermetic QEMU toolchains and
supporting calling rules for the QEMU family, including `qemu-user`,
`qemu-system`, and `qemu-img`.

The current toolchains are backed by static Linux prebuilts from
[`hermeticbuild/qemu-prebuilt`](https://github.com/hermeticbuild/qemu-prebuilt),
which publishes static QEMU user-mode, system-mode, `qemu-img`, and runtime
data artifacts.

## Current Support

Host execution platforms:

- Linux amd64 (`@platforms//os:linux`, `@platforms//cpu:x86_64`)
- Linux arm64 (`@platforms//os:linux`, `@platforms//cpu:aarch64`)

Emulated Linux target CPUs:

- `aarch64`
- `arm`
- `armv7` (uses `qemu-arm`; set QEMU CPU environment as needed)
- `i386`
- `mips64`
- `ppc`
- `ppc32` (uses `qemu-ppc`)
- `ppc64le`
- `riscv32`
- `riscv64`
- `s390x`
- `x86_32`
- `x86_64`

Current limitations:

- Linux `qemu-user` toolchains are registered and exposed through
  `qemu_binary`.
- Linux `qemu-system` and `qemu-img` toolchains are registered and exposed
  through providers for rule authors. There is no public VM-launching rule yet.
- The default module extension currently downloads QEMU `11.0.0` prebuilts
  from qemu-prebuilt release/artifact version `11.0.0.0`.

## Installation

Add `rules_qemu` to your `MODULE.bazel` and register the generated QEMU
toolchains:

```starlark
bazel_dep(name = "rules_qemu", version = "...")

qemu = use_extension("@rules_qemu//qemu/extension:qemu.bzl", "qemu")
use_repo(
    qemu,
    "qemu_system_toolchains",
    "qemu_user_toolchains",
)

register_toolchains(
    "@qemu_system_toolchains//:all",
    "@qemu_user_toolchains//:all",
)
```

## Running A Binary Under QEMU

Use `qemu_binary` to build an executable wrapper that runs a target-platform
binary through the matching QEMU user-mode emulator.

```starlark
load("@rules_qemu//qemu:qemu_binary.bzl", "qemu_binary")

cc_binary(
    name = "hello",
    srcs = ["hello.c"],
)

qemu_binary(
    name = "hello_riscv64",
    binary = ":hello",
    target_platform = "//platforms:linux_riscv64_musl",
)
```

Then run it like any other Bazel executable:

```console
bazel run //:hello_riscv64
```

`qemu_binary` applies a platform transition to `binary`, selects the QEMU
toolchain for that target platform, and emits a hermetic launcher containing
the target binary and emulator in its runfiles.

## Toolchain Selection

The module extension creates one `qemu-user` toolchain per supported host and
target CPU pair. Bazel selects the toolchain from:

- the execution platform, such as Linux x86_64 or Linux aarch64
- the requested target platform passed to `qemu_binary`

For example, on a Linux x86_64 executor, a `target_platform` with
`@platforms//cpu:riscv64` selects the static `qemu-riscv64` prebuilt for a
Linux amd64 host.

## QEMU System Toolchains

Rule authors can consume `@rules_qemu//qemu:system_toolchain_type` to access
hermetic `qemu-system-*`, `qemu-img`, and `share/qemu` runtime data. Consumers
provide their own `config_setting` labels and declare which QEMU system target
those settings select through the module extension.

```starlark
# MODULE.bazel
qemu = use_extension("@rules_qemu//qemu/extension:qemu.bzl", "qemu")
qemu.system_toolchain(
    system_target = "riscv64-softmmu",
    target_settings = ["//config:qemu_system_riscv64"],
)
use_repo(qemu, "qemu_system_toolchains")
register_toolchains("@qemu_system_toolchains//:all")
```

```starlark
# config/qemu_system_target.bzl
def _qemu_system_target_impl(_ctx):
    return []

qemu_system_target = rule(
    implementation = _qemu_system_target_impl,
    build_setting = config.string(flag = True),
)
```

```starlark
# config/BUILD.bazel
load(":qemu_system_target.bzl", "qemu_system_target")

qemu_system_target(
    name = "qemu_system_target",
    build_setting_default = "x86_64",
    visibility = ["//visibility:public"],
)

config_setting(
    name = "qemu_system_riscv64",
    flag_values = {
        ":qemu_system_target": "riscv64",
    },
    visibility = ["//visibility:public"],
)
```

```starlark
# BUILD.bazel
def _my_rule_impl(ctx):
    qemu = ctx.toolchains["@rules_qemu//qemu:system_toolchain_type"]
    qemu_system = qemu.qemu_system
    qemu_img = qemu.qemu_img
    system_data_files = qemu.system_data_files

my_rule = rule(
    implementation = _my_rule_impl,
    toolchains = ["@rules_qemu//qemu:system_toolchain_type"],
)
```

With this model, each configured rule instance resolves one QEMU system guest.
Select a different guest by changing the configuration so a different
`target_settings` label matches.

The corresponding `QemuSystemToolchainInfo` provider is available from
`@rules_qemu//qemu:qemu_system_toolchain.bzl`. It includes the selected
`qemu-system-*` binary, `qemu-img`, the `share/qemu` data directory for
locating `-L`, and target metadata such as `machine`,
`system_target`, and `target_arch`.

## Smoke Test Example

This repository includes an external-consumer smoke test in `e2e/smoke`.

```console
cd e2e/smoke
bazel test //...
```

The smoke workspace registers `rules_qemu`, builds simple C binaries for
multiple target platforms with the published LLVM toolchain, runs them through
`qemu_binary`, and starts `qemu-system` through QMP with the hermetic
`share/qemu` data path. It also starts a `qemu-system-riscv64` QMP smoke target
from the default host-configured test package to exercise explicit guest
selection.

## Roadmap

The intended scope is broader than user-mode emulation. Future work should add:

- public VM-launching rules built on the `qemu-system` toolchain provider
- version selection for prebuilts exposed through the module extension
- additional host platforms when static prebuilts are available
