load("@bazel_features//:features.bzl", "bazel_features")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

QEMU_VERSION = "11.0.0"

QEMU_RELEASES = {
    ("amd64", "aarch64"): "073f3afd4354c562aa2a0570cb0ce5b72b291a09769bcc90be026bbc155bd3f0",
    ("amd64", "arm"): "cd8a1ebce2262d21c75aee8867223c893980506b815247fedb10e7a6ccfe2a78",
    ("amd64", "i386"): "ebaf168f9bd1dc133d76875b9c9c6b723728d0c87a29bed6441a4174cefa5ee3",
    ("amd64", "mips64"): "1ba66799e09bcc59fb4502bc02a4ac8e60457954e0341ac0c44319e3bd8d5010",
    ("amd64", "ppc"): "099488f83f169912a70bf6cdaed6a43c858b407616588859d8ef8c605e9d9c37",
    ("amd64", "ppc64le"): "79da4873694daa49a779c066c3cea73e65da75fc3c83fcff73b9a614f6181dad",
    ("amd64", "riscv32"): "851713d19f379a5846c1e9063057d70f3a6f4d9140e158e7f002831fc9c41e36",
    ("amd64", "riscv64"): "b24eb60d33ce5d77d5b97ed85713dd4ff18c3366e35eba452781448f92ef3515",
    ("amd64", "s390x"): "8735feb8c7bbc64e755966150d3c52080e8aacf4a7a0a3d026b2c796988875c8",
    ("amd64", "x86_64"): "5a95c100c857e0f0a9732c940ce92b4e38e6d86365685d36c2fe69db13669a1f",
    ("arm64", "aarch64"): "368cbb5fcb21f7cc0558115283103a600e70c145c81506b02b6255798d1a1f35",
    ("arm64", "arm"): "e81a4ed7b8817187c2184520d573b5089661c7457d46d35a19511eb5c99f50d1",
    ("arm64", "i386"): "d2433cd1b965ed59e76af06840cc8367f9b60a5ec25c9cf889edc1f302c046b9",
    ("arm64", "mips64"): "e87d521fb9731812eb979f32e943b9e86474fee72153bce603b6929a3bb51f1f",
    ("arm64", "ppc"): "18608d644675197cf77e03f65bdd99d399509053d900e0f1f76026e9ef855173",
    ("arm64", "ppc64le"): "49618d23d75b9967ff8ee11f09670f317b937aa8e1cfbffa8ac68ea6df12536a",
    ("arm64", "riscv32"): "0e6fcf4c2f5afad4b418c3190e559fbb6ac51c2a5427baaf4dd781167ed21ff0",
    ("arm64", "riscv64"): "9d0a64fececb0fdfb8e48459e956dd41c4ab9a04668459bc9506bda1bf8c698e",
    ("arm64", "s390x"): "62e828be87518fd2496840ca10ba43fe989fc05c746b93f7ffc0c32703a80568",
    ("arm64", "x86_64"): "eca6fadce7ccf8d572216c78c6cf3124e49fafae625c80251ec7cac6bac7c250",
}

_TOOLCHAINS_BUILD = """\
load("@rules_qemu//qemu:declare_toolchains.bzl", "declare_toolchains")

package(default_visibility = ["//visibility:public"])

EXEC_PLATFORMS = [
    ("linux", "x86_64"),
    ("linux", "aarch64"),
]

TARGET_PLATFORMS = [
    ("linux", "aarch64"),
    ("linux", "arm"),
    ("linux", "i386"),
    ("linux", "mips64"),
    ("linux", "ppc"),
    ("linux", "ppc64le"),
    ("linux", "riscv32"),
    ("linux", "riscv64"),
    ("linux", "s390x"),
    ("linux", "x86_32"),
    ("linux", "x86_64"),
]

declare_toolchains(
    exec_platforms = EXEC_PLATFORMS,
    target_platforms = TARGET_PLATFORMS,
)
"""

_QEMU_BINARY_BUILD = """\
package(default_visibility = ["//visibility:public"])

exports_files(["{file}"])

filegroup(
    name = "qemu-{qemu_arch}",
    srcs = ["{file}"],
)
"""

def _qemu_toolchains_repository_impl(repository_ctx):
    repository_ctx.file("BUILD.bazel", _TOOLCHAINS_BUILD)

_qemu_toolchains_repository = repository_rule(
    implementation = _qemu_toolchains_repository_impl,
)

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
            urls = ["https://github.com/hermeticbuild/qemu-user-prebuilt/releases/download/{version}/qemu-user-{platform}.tar.zst".format(
                platform = platform,
                version = QEMU_VERSION,
            )],
        )

    _qemu_toolchains_repository(name = "qemu_user_toolchains")

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
