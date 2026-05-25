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

Rule authors can use `qemu_system_resolved_toolchain` to resolve hermetic
`qemu-system-*`, `qemu-img`, and `share/qemu` runtime data for an explicit QEMU
guest platform. The helper applies a QEMU-specific transition, so the emulated
guest platform does not have to be the Bazel target platform of the rule that
launches QEMU.

```starlark
load(
    "@rules_qemu//qemu:qemu_system_toolchain.bzl",
    "QemuSystemToolchainInfo",
    "qemu_system_resolved_toolchain",
)

qemu_system_resolved_toolchain(
    name = "qemu_system_riscv64",
    guest_platform = "@rules_qemu//qemu:system_guest_linux_riscv64",
)

def _my_rule_impl(ctx):
    qemu = ctx.attr.qemu[QemuSystemToolchainInfo]
    qemu_system = qemu.qemu_system
    qemu_img = qemu.qemu_img
    system_data_files = qemu.system_data_files

my_rule = rule(
    implementation = _my_rule_impl,
    attrs = {
        "qemu": attr.label(
            cfg = "exec",
            providers = [QemuSystemToolchainInfo],
        ),
    },
)

my_rule(
    name = "boot_riscv64",
    qemu = ":qemu_system_riscv64",
)
```

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
