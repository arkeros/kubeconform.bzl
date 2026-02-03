"""Module extension for kubeconform toolchain and Kubernetes schemas."""

load("//kubeconform:kubernetes_schemas.bzl", "kubernetes_schemas")
load("//kubeconform:versions.bzl", "DEFAULT_KUBECONFORM_VERSION", "KUBECONFORM_VERSIONS", "get_kubeconform_url")

def _detect_platform(ctx):
    """Detect the host platform for binary download."""
    os = ctx.os.name
    arch = ctx.os.arch

    if os == "mac os x" or os.startswith("darwin"):
        os_name = "darwin"
    elif os.startswith("linux"):
        os_name = "linux"
    elif os.startswith("windows"):
        os_name = "windows"
    else:
        fail("Unsupported OS: {}".format(os))

    if arch == "amd64" or arch == "x86_64":
        arch_name = "amd64"
    elif arch == "aarch64" or arch == "arm64":
        arch_name = "arm64"
    else:
        fail("Unsupported architecture: {}".format(arch))

    return "{}_{}".format(os_name, arch_name)

def _get_exec_constraints(platform):
    """Get exec constraints for a platform."""
    parts = platform.split("_")
    os_constraint = {"darwin": "@platforms//os:macos", "linux": "@platforms//os:linux", "windows": "@platforms//os:windows"}[parts[0]]
    arch_constraint = {"amd64": "@platforms//cpu:x86_64", "arm64": "@platforms//cpu:aarch64"}[parts[1]]
    return [os_constraint, arch_constraint]

def _kubeconform_repo_impl(ctx):
    """Download kubeconform binary and create toolchain."""
    platform = _detect_platform(ctx)
    version = ctx.attr.version
    key = "{}-{}".format(version, platform)

    if key not in KUBECONFORM_VERSIONS:
        fail("Unsupported kubeconform version/platform: {}".format(key))

    filename, sha256 = KUBECONFORM_VERSIONS[key]
    url = get_kubeconform_url(version, filename)

    ctx.download_and_extract(url = url, sha256 = sha256)

    binary_name = "kubeconform.exe" if platform.startswith("windows") else "kubeconform"

    ctx.file("BUILD.bazel", """
package(default_visibility = ["//visibility:public"])

load("@kubeconform.bzl//kubeconform/toolchain:toolchain.bzl", "kubeconform_toolchain")

exports_files(["{binary}"])

kubeconform_toolchain(
    name = "toolchain",
    kubeconform = ":{binary}",
)

toolchain(
    name = "kubeconform_toolchain",
    exec_compatible_with = {constraints},
    toolchain = ":toolchain",
    toolchain_type = "@kubeconform.bzl//:toolchain_type",
)
""".format(binary = binary_name, constraints = _get_exec_constraints(platform)))

kubeconform_repo = repository_rule(
    implementation = _kubeconform_repo_impl,
    attrs = {"version": attr.string(default = DEFAULT_KUBECONFORM_VERSION)},
)

def _kubeconform_extension_impl(ctx):
    for mod in ctx.modules:
        for toolchain in mod.tags.toolchain:
            kubeconform_repo(
                name = "kubeconform_toolchains",
                version = toolchain.version or DEFAULT_KUBECONFORM_VERSION,
            )
        for schemas in mod.tags.kubernetes_schemas:
            kubernetes_schemas(
                name = "kubernetes_schemas",
                kubernetes_version = schemas.kubernetes_version,
                extra_resource_types = schemas.extra_resource_types,
            )

kubeconform = module_extension(
    implementation = _kubeconform_extension_impl,
    tag_classes = {
        "toolchain": tag_class(attrs = {"version": attr.string()}),
        "kubernetes_schemas": tag_class(attrs = {
            "kubernetes_version": attr.string(mandatory = True),
            "extra_resource_types": attr.string_list(),
        }),
    },
)
