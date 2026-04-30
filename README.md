# rules_qemu

Bazel rules and toolchains for running target binaries with QEMU user-mode emulators.

```starlark
bazel_dep(name = "rules_qemu", version = "...")

qemu = use_extension("@rules_qemu//qemu/extension:qemu.bzl", "qemu")
use_repo(qemu, "qemu_user_toolchains")

register_toolchains("@qemu_user_toolchains//:all")
```

```starlark
load("@rules_qemu//qemu:qemu_binary.bzl", "qemu_binary")

qemu_binary(
    name = "hello_riscv64",
    binary = ":hello",
    target_platform = "//platforms:linux_riscv64_musl",
)
```
