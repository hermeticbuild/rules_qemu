# rules_qemu

`rules_qemu` provides Bazel rules and toolchains for running target binaries
with hermetic QEMU binaries.

The goal of this project is to provide fully hermetic QEMU toolchains and
supporting calling rules for the QEMU family, including `qemu-user`,
`qemu-system`, and `qemu-img`. Today, only `qemu-user` is supported.

The current `qemu-user` toolchains are backed by static Linux prebuilts from
[`hermeticbuild/qemu-user-prebuilt`](https://github.com/hermeticbuild/qemu-user-prebuilt),
which publishes static `qemu-user` binaries for many QEMU versions.

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

- Only Linux `qemu-user` toolchains are registered.
- `qemu-system` and `qemu-img` rules/toolchains are planned but not implemented.
- The default module extension currently downloads QEMU `11.0.0` prebuilts.

## Installation

Add `rules_qemu` to your `MODULE.bazel` and register the generated QEMU user
toolchains:

```starlark
bazel_dep(name = "rules_qemu", version = "...")

qemu = use_extension("@rules_qemu//qemu/extension:qemu.bzl", "qemu")
use_repo(qemu, "qemu_user_toolchains")

register_toolchains("@qemu_user_toolchains//:all")
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

## Smoke Test Example

This repository includes an external-consumer smoke test in `e2e/smoke`.

```console
cd e2e/smoke
bazel test //...
```

The smoke workspace registers `rules_qemu`, builds simple C binaries for
multiple target platforms with the published LLVM toolchain, and runs them
through `qemu_binary`.

## Roadmap

The intended scope is broader than user-mode emulation. Future work should add:

- hermetic `qemu-system` toolchains and calling rules
- hermetic `qemu-img` toolchains and calling rules
- version selection for prebuilts exposed through the module extension
- additional host platforms when static prebuilts are available
