# Example BUILD file demonstrating kubeconform_test usage with a compiled kubeconform toolchain
#
# This example compiles kubeconform from Go source and registers it as a toolchain.
# This is useful when you need:
# - Hermetic builds with kubeconform compiled from source
# - Custom kubeconform patches or modifications
# - Integration with existing Go dependency management

load("@kubeconform.bzl//:kubeconform.bzl", "kubeconform_test", "kubeconform_toolchain", "openapi2jsonschema")

# Define a kubeconform toolchain using the compiled binary
kubeconform_toolchain(
    name = "compiled_kubeconform_toolchain",
    kubeconform = "@com_github_yannh_kubeconform//cmd/kubeconform",
    visibility = ["//visibility:public"],
)

# Register the toolchain (referenced in MODULE.bazel)
toolchain(
    name = "kubeconform_toolchain",
    toolchain = ":compiled_kubeconform_toolchain",
    toolchain_type = "@kubeconform.bzl//:toolchain_type",
)

# Generate JSON schema from CRD
openapi2jsonschema(
    name = "widget_schema",
    src = "crd.yaml",
    outs = ["example.com_v1_widget.json"],
)

# Validate core Kubernetes manifest (uses @kubernetes_schemas)
kubeconform_test(
    name = "deployment_test",
    data = ["deployment.yaml"],
    schemas = [],
)

# Validate custom resource using generated schema
kubeconform_test(
    name = "widget_test",
    data = ["widget.yaml"],
    kubernetes_schemas = [],
    schemas = [":widget_schema"],
)
