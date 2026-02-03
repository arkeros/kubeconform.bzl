"""Repository rule to download core Kubernetes JSON schemas for hermetic validation."""

# Core Kubernetes resource types commonly used in manifests.
# Maps kind -> (group_prefix for filename, api_version)
# Filename pattern: {kind}{-group}-{version}.json (lowercase, standalone-strict)
_CORE_RESOURCE_TYPES = {
    "clusterrole": ("rbac", "v1"),
    "clusterrolebinding": ("rbac", "v1"),
    "configmap": ("", "v1"),
    "cronjob": ("batch", "v1"),
    "daemonset": ("apps", "v1"),
    "deployment": ("apps", "v1"),
    "horizontalpodautoscaler": ("autoscaling", "v2"),
    "ingress": ("networking", "v1"),
    "job": ("batch", "v1"),
    "namespace": ("", "v1"),
    "networkpolicy": ("networking", "v1"),
    "persistentvolumeclaim": ("", "v1"),
    "pod": ("", "v1"),
    "poddisruptionbudget": ("policy", "v1"),
    "role": ("rbac", "v1"),
    "rolebinding": ("rbac", "v1"),
    "secret": ("", "v1"),
    "service": ("", "v1"),
    "serviceaccount": ("", "v1"),
    "statefulset": ("apps", "v1"),
}

def _schema_filename(kind, group, version):
    """Build the kubeconform schema filename."""
    if group:
        return "{}-{}-{}.json".format(kind, group, version)
    return "{}-{}.json".format(kind, version)

def _kubernetes_schemas_impl(ctx):
    k8s_version = ctx.attr.kubernetes_version
    base_url = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v{version}-standalone-strict/{filename}"

    # Determine which resource types to download
    resource_types = dict(_CORE_RESOURCE_TYPES)
    for extra in ctx.attr.extra_resource_types:
        parts = extra.split(":")
        if len(parts) == 3:
            resource_types[parts[0]] = (parts[1], parts[2])
        elif len(parts) == 2:
            resource_types[parts[0]] = ("", parts[1])
        else:
            fail("extra_resource_types entry must be 'kind:group:version' or 'kind:version', got: " + extra)

    filenames = []
    for kind, (group, version) in resource_types.items():
        filename = _schema_filename(kind, group, version)
        filenames.append(filename)
        url = base_url.format(version = k8s_version, filename = filename)
        ctx.download(
            url = url,
            output = filename,
        )

    # Generate BUILD file exposing all schemas as a filegroup
    srcs = ", ".join(['"{}"'.format(f) for f in sorted(filenames)])
    ctx.file("BUILD.bazel", """
package(default_visibility = ["//visibility:public"])

filegroup(
    name = "schemas",
    srcs = [{srcs}],
)
""".format(srcs = srcs))

kubernetes_schemas = repository_rule(
    implementation = _kubernetes_schemas_impl,
    attrs = {
        "kubernetes_version": attr.string(mandatory = True),
        "extra_resource_types": attr.string_list(
            doc = "Additional resource types as 'kind:group:version' or 'kind:version' (core API).",
        ),
    },
    doc = "Downloads core Kubernetes JSON schemas for hermetic kubeconform validation.",
)
