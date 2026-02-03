"Re-export for syntax sugar load."

load(
    "//kubeconform:defs.bzl",
    _expect_kubeconform_failure = "expect_kubeconform_failure",
    _kubeconform_test = "kubeconform_test",
    _openapi2jsonschema = "openapi2jsonschema",
)
load("//kubeconform/toolchain:toolchain.bzl", _KubeconformInfo = "KubeconformInfo", _kubeconform_toolchain = "kubeconform_toolchain")

KubeconformInfo = _KubeconformInfo
kubeconform_toolchain = _kubeconform_toolchain
kubeconform_test = _kubeconform_test
expect_kubeconform_failure = _expect_kubeconform_failure
openapi2jsonschema = _openapi2jsonschema
