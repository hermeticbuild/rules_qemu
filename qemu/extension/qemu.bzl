"""Module extension for QEMU prebuilts."""

load("@bazel_features//:features.bzl", "bazel_features")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//qemu/private:qemu_toolchains_repository.bzl", "qemu_system_toolchains_repository", "qemu_toolchains_repository")

QEMU_VERSION = "11.0.0"
QEMU_PREBUILT_RELEASE = "11.0.0.0"
QEMU_PREBUILT_ARTIFACT_VERSION = "11.0.0.0"
QEMU_PREBUILT_REPOSITORY = "hermeticbuild/qemu-prebuilt"

QEMU_RELEASES = {
    ("amd64", "aarch64"): "15e4430509291373ecdd5891c463538fbb6e8f11acd88342b109f741d0f37089",
    ("amd64", "arm"): "31e11ebd288b197f9c846f2eb6fce897d2fe57dee1e0e94b37c91f3116389ffc",
    ("amd64", "i386"): "f1c7a6e9c40e23aedba0fff2db90c0fa12232c19bcd2f3d515842b9189ed4e9e",
    ("amd64", "mips64"): "1d31baec7f9630d90d026de3b0f27821ce2db42211ca57af4f334cf4d6ad0ebe",
    ("amd64", "ppc"): "6f814714b06b292ff3fcc61cfb563a7abff11a08a4bd33bba9ceabf3c796bc58",
    ("amd64", "ppc64le"): "fbc637e430067871980ce50cabaef99c9f2b43c72db049e515d567d8378600d8",
    ("amd64", "riscv32"): "b0ddec8ba3c15adab1926f24d936da34bedfcd265f5ab86d12ac97532e8c67f3",
    ("amd64", "riscv64"): "df91fa4a2e42ed93f7e341025fae9608b3d79d7af974ffcad31a979eac4e84c3",
    ("amd64", "s390x"): "c0702c8c4771efeb62715d81c2a4cbe6d5495f491f53de7d3fbadf9f8eccfad2",
    ("amd64", "x86_64"): "663c75fded5dcb78758f47cd2c4bba1ed37c3a7bf21377f93f6d1b2a9ebefdf5",
    ("arm64", "aarch64"): "2bd892f0daf464bbfff7d9dfdff207a5111ef63f604331f061d72eafbeb19f82",
    ("arm64", "arm"): "804dcfab2af29422260e2e897a0aebc315ff8e704894855b4fa7cdeae2b6cd5d",
    ("arm64", "i386"): "10da56d614893df2f554d5d26cc78bed1d3f5025677491a669281a60c0cbe687",
    ("arm64", "mips64"): "24e1f6a708f2a91929848c6287e0c22715a669d46877640ead8074c6ca513331",
    ("arm64", "ppc"): "c610891c5aeec0c21c2b2f2843a3ce810ea80f32abbdcf33447f7839e60b7371",
    ("arm64", "ppc64le"): "d5cf08c2e8611e3c6a42d43a933ace17171e22cfd0e7f217e2310f810c226260",
    ("arm64", "riscv32"): "469666b09d2f7145c3061e9e4433f296eb473633f5082915caf144ca2f5f614f",
    ("arm64", "riscv64"): "960b3818a0ed97ce239af0431f87a019b1b13f6f89b77cb71624bf3ecec27282",
    ("arm64", "s390x"): "c4d851a896563e57eba42643c96d7090f28675f13183e190655a2908db0d1e50",
    ("arm64", "x86_64"): "2ddef57cfc09794d4489849298011e64d792f4f5f318b3f07f18245b972e6863",
}

QEMU_IMG_RELEASES = {
    "amd64": "38a6b0cb95abd76c7a510e3ffd2cc95ed6e04cec1056129a33f56f5cfb973f44",
    "arm64": "2956116398dae790a0818ebe90a5d9bcb70bd1b929a5c07a5a0cb1e21e2ca889",
}

QEMU_SYSTEM_DATA_RELEASES = {
    "amd64": "b83e187ca9c400610ee23af857128827eeaaf9160ba96c0adf5283332e289937",
    "arm64": "e601e5c96473e44fcc48f4d6a27a47d4638f38737eb26a2f62b3b8409788f493",
}

QEMU_SYSTEM_RELEASES = {
    ("amd64", "aarch64-softmmu"): "ae75f433e49bc0171b76d261f48f3faf3eb5fa904fa9c9e9a237c7bc1b6b9598",
    ("amd64", "arm-softmmu"): "49548d9ea2139e02c05d45468f0160e4afad64960950620cbd1815ff4f2be6b7",
    ("amd64", "i386-softmmu"): "3a2ae495051d0e3496ce57edae73991afdbe0657e70676d752647b2063ba2fe7",
    ("amd64", "mips64-softmmu"): "ad19630d06aaf7883007e3affa0c88be698cd59b238a37df000841496df9cc13",
    ("amd64", "ppc-softmmu"): "9356bd370b52d55d885508e501931c294959bb344f7cb511439346f249047cb3",
    ("amd64", "ppc64-softmmu"): "64f48af65d17b450e9211d37aea4b71e4824c026bbb73dd7195d31ef815f7a26",
    ("amd64", "riscv32-softmmu"): "09a71fd4470f983c030d76777679f34fa77be66e1eac23ac643c31bb0d33926e",
    ("amd64", "riscv64-softmmu"): "a8464bd41c7bc802bf37c2c8fcf4aa7c31e4a7d56b17b4e0907631d543adeba6",
    ("amd64", "s390x-softmmu"): "292d5ba02218b4ff94b00652058eb2d3185bbdd7cb20fc800f38ae023f666d8b",
    ("amd64", "x86_64-softmmu"): "fa0f2ec2659c477e5c6c54ec01abbb03ca06f9692a1a0f1ba89640986b5a23e4",
    ("arm64", "aarch64-softmmu"): "76b4a21e2af0c4e74a7f5ebc4191b0effd153b9eff9234836a3910ad69b2b6b4",
    ("arm64", "arm-softmmu"): "d5227ad40604fb48be3802dd7eae7477fc9107edf9cc54f28c4f1ba367927b99",
    ("arm64", "i386-softmmu"): "ccf692ab3b1a88d039594c1e3d952c5fc03c4f57acc1f58554d5019d7a946c8e",
    ("arm64", "mips64-softmmu"): "daab9a3b9bd5b3af23046e5676b843b161439fcd6c1a217ab90ab6a2489341b8",
    ("arm64", "ppc-softmmu"): "dae60c9d8382ea6ddf0ead71ff5c2f29e5dcd40fd989dfdcb8f553dd2d66ffbb",
    ("arm64", "ppc64-softmmu"): "87af1a2151342bdc1748c1de3eb764736837b4c26a21a93f46e9a0fb9695b8c6",
    ("arm64", "riscv32-softmmu"): "1c30e9a3d3541ebe83c070270f37dc5878fb0ab8a780120888c3c0c62f452d53",
    ("arm64", "riscv64-softmmu"): "7450a1f58b41a825157b7768d2ab0aa1021220b5be8b975f3ebf6b90f408e71b",
    ("arm64", "s390x-softmmu"): "cf7806e35dfe234a6e2be33d8aa7ba0834807fb24e1c5b6aadebb045052b1687",
    ("arm64", "x86_64-softmmu"): "f274af7fe79ee5c635fa2493599189734c96594cb71b3a82ec09fd20f256ad2b",
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

def _system_guest_platform_entries(module_ctx):
    entries = []
    seen_platforms = {}

    for module in module_ctx.modules:
        for tag in module.tags.system_guest_platform:
            platform = str(tag.platform)
            target_platform = (tag.target_os, tag.target_cpu)
            if platform in seen_platforms:
                if seen_platforms[platform] != target_platform:
                    fail("QEMU system guest platform {} declared for both {} and {}".format(
                        platform,
                        seen_platforms[platform],
                        target_platform,
                    ))
                continue

            seen_platforms[platform] = target_platform
            name = "guest_{}_{}_{}".format(len(entries), tag.target_os, tag.target_cpu)
            entries.append("""    {{
        "name": "{name}",
        "platform": "{platform}",
        "target_cpu": "{target_cpu}",
        "target_os": "{target_os}",
    }},""".format(
                name = name,
                platform = platform,
                target_cpu = tag.target_cpu,
                target_os = tag.target_os,
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
        system_guest_platforms = _system_guest_platform_entries(module_ctx),
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

_SYSTEM_GUEST_PLATFORM_TAG = tag_class(
    attrs = {
        "platform": attr.label(
            mandatory = True,
            doc = "User-defined platform label that selects this QEMU guest.",
        ),
        "target_cpu": attr.string(
            mandatory = True,
            doc = "QEMU guest CPU name, such as x86_64, aarch64, or riscv64.",
        ),
        "target_os": attr.string(
            mandatory = True,
            doc = "QEMU guest OS name, such as linux.",
        ),
    },
    doc = "Declares a user-owned platform label as a QEMU system guest selector.",
)

qemu = module_extension(
    implementation = _qemu_impl,
    doc = "Extension for downloading static Linux QEMU prebuilts.",
    tag_classes = {
        "system_guest_platform": _SYSTEM_GUEST_PLATFORM_TAG,
    },
)
