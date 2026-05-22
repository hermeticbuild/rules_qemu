"""Module extension for QEMU user-mode prebuilts."""

load("@bazel_features//:features.bzl", "bazel_features")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//qemu/private:qemu_toolchains_repository.bzl", "qemu_toolchains_repository")

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

_QEMU_BINARY_BUILD = """\
package(default_visibility = ["//visibility:public"])

exports_files(["{file}"])

filegroup(
    name = "qemu-{qemu_arch}",
    srcs = ["{file}"],
)
"""

def _qemu_impl(module_ctx):
    """Implementation of the QEMU user-mode prebuilt module extension."""

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

    qemu_toolchains_repository(name = "qemu_user_toolchains")

    metadata_kwargs = {}
    if bazel_features.external_deps.extension_metadata_has_reproducible:
        metadata_kwargs["reproducible"] = True

    return module_ctx.extension_metadata(
        root_module_direct_deps = ["qemu_user_toolchains"],
        root_module_direct_dev_deps = [],
        **metadata_kwargs
    )

qemu = module_extension(
    implementation = _qemu_impl,
    doc = "Extension for downloading static Linux user-mode QEMU prebuilts.",
)
