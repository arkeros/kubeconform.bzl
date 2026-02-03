load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

# Prefer generated BUILD files to be called BUILD over BUILD.bazel
# gazelle:build_file_name BUILD,BUILD.bazel
# gazelle:prefix github.com/arkeros/kubeconform.bzl
# gazelle:exclude bazel-kubeconform.bzl

toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)

exports_files([
    "BUILD",
    "LICENSE",
    "MODULE.bazel",
])

bzl_library(
    name = "kubeconform",
    srcs = ["kubeconform.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//kubeconform:defs",
        "//kubeconform/toolchain",
    ],
)
