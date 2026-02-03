load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ["//visibility:public"])

bzl_library(
    name = "defs",
    srcs = ["defs.bzl"],
    deps = [
        ":openapi2jsonschema",
        "//kubeconform/toolchain",
    ],
)

bzl_library(
    name = "extensions",
    srcs = ["extensions.bzl"],
    deps = [
        ":kubernetes_schemas",
        ":versions",
    ],
)

bzl_library(
    name = "kubernetes_schemas",
    srcs = ["kubernetes_schemas.bzl"],
)

bzl_library(
    name = "openapi2jsonschema",
    srcs = ["openapi2jsonschema.bzl"],
)

bzl_library(
    name = "versions",
    srcs = ["versions.bzl"],
)
