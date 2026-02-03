load("@kubeconform.bzl//:kubeconform.bzl", "kubeconform_test", "openapi2jsonschema")

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
