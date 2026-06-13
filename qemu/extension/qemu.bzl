"""Module extension for QEMU prebuilts."""

load("@bazel_features//:features.bzl", "bazel_features")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//qemu/private:qemu_toolchains_repository.bzl", "qemu_system_toolchains_repository", "qemu_toolchains_repository")

QEMU_VERSION = "11.0.0"
QEMU_PREBUILT_RELEASE = "11.0.0.1"
QEMU_PREBUILT_ARTIFACT_VERSION = "11.0.0.1"
QEMU_PREBUILT_REPOSITORY = "hermeticbuild/qemu-prebuilt"

QEMU_RELEASES = {
    ("amd64", "aarch64"): "cc3bf42da8f219cd314a7806053c73cca166bf14c288daf5b6105e66590a6dee",
    ("amd64", "arm"): "7efa7a2dfb1a325dd514e16b67d38a6ead24b0bd5326ac0b1b8e8b6667c01698",
    ("amd64", "i386"): "60cc85a81c4cea6072230211b0cc1742557a6d57f53638d03d8d3c655c366872",
    ("amd64", "mips64"): "1f7d80af0b340b9ad7dec24e6ea01d7028a60e55ebfa1d7ac61a5418f4127621",
    ("amd64", "ppc"): "cd90ee01c78cfe2065195076dc9f866cff91cc7aa39c07961eb4f82bbf9eec2a",
    ("amd64", "ppc64le"): "21b1474ff3e9f05f2abca931659d70506000dd9413fb8662444f4ad739e3aa63",
    ("amd64", "riscv32"): "1d52e2a9e710a39eb7a7e0a6ee1a4b4a964625512cc75ebcd1e1b18c8678367b",
    ("amd64", "riscv64"): "b974c689b39e704696eed04500e9a2da4105f0b643e5119d01ef4826d6c7f0a0",
    ("amd64", "s390x"): "6b0cc9d4afee60b5d5f960622aa77c926b80366f7454d027cf5c0c2e29712e86",
    ("amd64", "x86_64"): "911d8c4dd7ca3780fe11adfa8db52a397e319b4feb46398b2e7488590c8040b6",
    ("arm64", "aarch64"): "fa6a9e126306ab3f06f718473425d6094b7336cac7d21a9328a36af673e5d0a4",
    ("arm64", "arm"): "56220cf250f745253c05f86d55dcccf2d4bcab61840e744a12bda781f735b035",
    ("arm64", "i386"): "7400ebdfa9020e86847320d0f412906afb0d634e09938792b36340aa0ecf67be",
    ("arm64", "mips64"): "1d9aeb6c36c2cb23ffd8169393dc7de83122664a2d508d27f56a3369c49e413a",
    ("arm64", "ppc"): "0572c14bf243f4c05aaa0170fea140a4763db2495cede7ec41f705ebf5981e3e",
    ("arm64", "ppc64le"): "ab0cb3154f6fa2d6ad91f300e41af82e35b6f9722d99d28ddb787f31dbe399a0",
    ("arm64", "riscv32"): "1076332ae82dfac4102778c5aedbd45eed5f0386038812328855e7d802d148f4",
    ("arm64", "riscv64"): "463545d675e5df5be0cc493c6822cd00c8708f8bff0b98e6d4e5ad1dcb169e39",
    ("arm64", "s390x"): "d864b9e065e41495b593fd0d5038e000f7e32b1a47eff3ae6d8c54a8c238e76d",
    ("arm64", "x86_64"): "58d31d097b72207702458bcd5927337e3428bad3f97d3075ff6c7b4ca13ecf50",
}

QEMU_IMG_RELEASES = {
    "amd64": "b58c4eb7e8e13a100dba36f4b871cfa7848fdbfece08bad8bbc9ec57cfeaca13",
    "arm64": "af1709cfbd65fbe94e3e9fc7d8dca9daf2cee63864768aaece41ccf1f1cf9888",
}

QEMU_SYSTEM_DATA_RELEASES = {
    "amd64": "2525218347b647962bed5d0b37d3093e434b8c83e5fd78de910d43bec6154fff",
    "arm64": "a5f02a4dfacba6405e3f8982ac22877a02553bec527afaffea3a941208345527",
}

QEMU_SYSTEM_RELEASES = {
    ("amd64", "aarch64-softmmu"): "47385316ca599ad1cd11b212ee34ba39315231484ddf0aca735ee999509ece4c",
    ("amd64", "arm-softmmu"): "3ece31b0bc998717fd432ebd5b158554edc691a8b9ea88e4b29729feebcfda08",
    ("amd64", "i386-softmmu"): "e6bdd05def107dff47ace3ebed0424bb3ed7e00ea78151f957d941fa02206a86",
    ("amd64", "mips64-softmmu"): "b7c1de2cc8ba1ab0742be4efd3a3b4de66260b2e393618fde31a614219841f84",
    ("amd64", "ppc-softmmu"): "78af750d8515a460207a767732e1f016904f3e58077336f679a2ee1c87453e17",
    ("amd64", "ppc64-softmmu"): "08331f7cad461cadb24457281ccb374b5d10824d141df990d894f02d1965da18",
    ("amd64", "riscv32-softmmu"): "3f8f1872b6ed5b411ebc41c77f1db585407345da4616abfea2d3e305f1260622",
    ("amd64", "riscv64-softmmu"): "a5a49730412ffa138b9c1703342efa7beb1bee0c57f8e7d249d7c8186b4dfb55",
    ("amd64", "s390x-softmmu"): "67cc84cd91e594c6402bd7186b578750b36d3c6349f14960cd7f578ae8768c8f",
    ("amd64", "x86_64-softmmu"): "b84d359893a0a1d565f368adb8290933ef9c99431acd98cff0fc4c9b35de3d22",
    ("arm64", "aarch64-softmmu"): "24a231d21b4b580fb939f9689d254a5414433b23fa0cd4e64e90ce67fdb47e2c",
    ("arm64", "arm-softmmu"): "e23de8f0ea440e5f98121dfe9725f7733feda27e8f7739ed50977b34bdea3f14",
    ("arm64", "i386-softmmu"): "c9466af203c9696278065591ca565294fb2a87b3d04e85161dea0bf778339e8e",
    ("arm64", "mips64-softmmu"): "77275e8ca8c45b49cb6ad4bfac1beb103620fb43a26077cbc07d5ad46017eecb",
    ("arm64", "ppc-softmmu"): "d263c3cbebd0e05e94259dbbb36f6bbba14e736c64566d1da22ac06cd8668a4f",
    ("arm64", "ppc64-softmmu"): "add0986c9a8af4d962b11281dfeb60b6c15c3c47a258187324c24ae3e277bb54",
    ("arm64", "riscv32-softmmu"): "ed6410c0abe7283e983abbd8659a3b12886a9d555f68ce15ec3839f1179ffd1f",
    ("arm64", "riscv64-softmmu"): "a666e381eaea1b84f88de615e683f169f065fe1eeced413c21078811aeb3244c",
    ("arm64", "s390x-softmmu"): "2f9b547aab4c0e6b935c826e66d20d0191728b47869e5a14835af0e90bf66484",
    ("arm64", "x86_64-softmmu"): "38996b463c6bd1c12c0c80c6fe47192c33a4c6cb88e7b97e1e4f67ecd41395f1",
}

_QEMU_BINARY_BUILD = """\
package(default_visibility = ["//visibility:public"])

exports_files(["{file}"])

filegroup(
    name = "qemu-{qemu_arch}",
    srcs = ["{file}"],
)
"""

_QEMU_IMG_BUILD = """\
package(default_visibility = ["//visibility:public"])

exports_files(["bin/qemu-img"])

filegroup(
    name = "qemu-img",
    srcs = ["bin/qemu-img"],
)
"""

_QEMU_SYSTEM_BINARY_BUILD = """\
package(default_visibility = ["//visibility:public"])

exports_files(["bin/{binary}"])

filegroup(
    name = "{binary}",
    srcs = ["bin/{binary}"],
)
"""

_QEMU_SYSTEM_DATA_BUILD = """\
package(default_visibility = ["//visibility:public"])

exports_files(["share/qemu"])

filegroup(
    name = "qemu-system-data",
    srcs = ["share/qemu"],
)
"""

def _system_toolchain_entries(module_ctx):
    entries = []
    seen_toolchains = {}

    for module in module_ctx.modules:
        for tag in module.tags.system_toolchain:
            target_settings = [str(target_setting) for target_setting in tag.target_settings]
            key = (tag.system_target, tuple(target_settings))
            if key in seen_toolchains:
                previous = seen_toolchains[key]
                if previous != (tag.machine, tag.target_arch):
                    fail("QEMU system toolchain {} with target_settings {} declared with conflicting metadata".format(
                        tag.system_target,
                        target_settings,
                    ))
                continue

            seen_toolchains[key] = (tag.machine, tag.target_arch)
            name = "system_{}_{}".format(len(entries), tag.system_target.replace("-", "_"))
            target_settings_repr = "\n".join([
                '            "{}",'.format(target_setting)
                for target_setting in target_settings
            ])
            entries.append("""    {{
        "machine": "{machine}",
        "name": "{name}",
        "system_target": "{system_target}",
        "target_arch": "{target_arch}",
        "target_settings": [
{target_settings}
        ],
    }},""".format(
                machine = tag.machine,
                name = name,
                system_target = tag.system_target,
                target_arch = tag.target_arch,
                target_settings = target_settings_repr,
            ))

    return "\n".join(entries)

def _qemu_impl(module_ctx):
    """Implementation of the QEMU prebuilt module extension."""

    for (exec_arch, qemu_arch), sha256 in QEMU_RELEASES.items():
        platform = "linux-{}-{}".format(exec_arch, qemu_arch)
        repo_platform = "linux_{}_{}".format(exec_arch, qemu_arch)
        http_archive(
            name = "qemu_user_prebuilt_{}".format(repo_platform),
            build_file_content = _QEMU_BINARY_BUILD.format(
                file = "qemu-user-{}".format(platform),
                qemu_arch = qemu_arch,
            ),
            sha256 = sha256,
            urls = ["https://github.com/{repository}/releases/download/{release}/qemu-user-{platform}-{version}.tar.zst".format(
                platform = platform,
                release = QEMU_PREBUILT_RELEASE,
                repository = QEMU_PREBUILT_REPOSITORY,
                version = QEMU_PREBUILT_ARTIFACT_VERSION,
            )],
        )

    for exec_arch, sha256 in QEMU_IMG_RELEASES.items():
        http_archive(
            name = "qemu_img_prebuilt_linux_{}".format(exec_arch),
            build_file_content = _QEMU_IMG_BUILD,
            sha256 = sha256,
            urls = ["https://github.com/{repository}/releases/download/{release}/qemu-img-linux-{exec_arch}-{version}.tar.zst".format(
                exec_arch = exec_arch,
                release = QEMU_PREBUILT_RELEASE,
                repository = QEMU_PREBUILT_REPOSITORY,
                version = QEMU_PREBUILT_ARTIFACT_VERSION,
            )],
        )

    for exec_arch, sha256 in QEMU_SYSTEM_DATA_RELEASES.items():
        http_archive(
            name = "qemu_system_data_prebuilt_linux_{}".format(exec_arch),
            build_file_content = _QEMU_SYSTEM_DATA_BUILD,
            sha256 = sha256,
            urls = ["https://github.com/{repository}/releases/download/{release}/qemu-system-data-linux-{exec_arch}-{version}.tar.zst".format(
                exec_arch = exec_arch,
                release = QEMU_PREBUILT_RELEASE,
                repository = QEMU_PREBUILT_REPOSITORY,
                version = QEMU_PREBUILT_ARTIFACT_VERSION,
            )],
        )

    for (exec_arch, system_target), sha256 in QEMU_SYSTEM_RELEASES.items():
        binary = "qemu-system-{}".format(system_target[:-len("-softmmu")])
        repo_system_target = system_target.replace("-", "_")
        http_archive(
            name = "qemu_system_bin_prebuilt_linux_{}_{}".format(exec_arch, repo_system_target),
            build_file_content = _QEMU_SYSTEM_BINARY_BUILD.format(binary = binary),
            sha256 = sha256,
            urls = ["https://github.com/{repository}/releases/download/{release}/qemu-system-bin-linux-{exec_arch}-{system_target}-{version}.tar.zst".format(
                exec_arch = exec_arch,
                release = QEMU_PREBUILT_RELEASE,
                repository = QEMU_PREBUILT_REPOSITORY,
                system_target = system_target,
                version = QEMU_PREBUILT_ARTIFACT_VERSION,
            )],
        )

    qemu_toolchains_repository(name = "qemu_user_toolchains")
    qemu_system_toolchains_repository(
        name = "qemu_system_toolchains",
        system_toolchains = _system_toolchain_entries(module_ctx),
    )

    metadata_kwargs = {}
    if bazel_features.external_deps.extension_metadata_has_reproducible:
        metadata_kwargs["reproducible"] = True

    return module_ctx.extension_metadata(
        root_module_direct_deps = [
            "qemu_system_toolchains",
            "qemu_user_toolchains",
        ],
        root_module_direct_dev_deps = [],
        **metadata_kwargs
    )

_SYSTEM_TOOLCHAIN_TAG = tag_class(
    attrs = {
        "machine": attr.string(
            doc = "Default machine hint for this QEMU system target. Defaults to rules_qemu's target metadata.",
        ),
        "system_target": attr.string(
            mandatory = True,
            doc = "QEMU system target, such as x86_64-softmmu, aarch64-softmmu, or riscv64-softmmu.",
        ),
        "target_arch": attr.string(
            doc = "Guest architecture metadata exposed by QemuSystemToolchainInfo. Defaults to rules_qemu's target metadata.",
        ),
        "target_settings": attr.label_list(
            mandatory = True,
            doc = "User-defined config_setting labels passed to the generated toolchain target_settings.",
        ),
    },
    doc = "Declares a QEMU system toolchain selected by user-owned target_settings.",
)

qemu = module_extension(
    implementation = _qemu_impl,
    doc = "Extension for downloading static Linux QEMU prebuilts.",
    tag_classes = {
        "system_toolchain": _SYSTEM_TOOLCHAIN_TAG,
    },
)
