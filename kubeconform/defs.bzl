"""Kubeconform rules for Kubernetes manifest validation."""

load("//kubeconform:openapi2jsonschema.bzl", _openapi2jsonschema = "openapi2jsonschema")
load("//kubeconform/toolchain:toolchain.bzl", "KubeconformInfo")

openapi2jsonschema = _openapi2jsonschema

def _get_schema_dir(short_path):
    """Get the directory portion of a short_path, or '.' if in root."""
    if "/" in short_path:
        return short_path.rsplit("/", 1)[0]
    return "."

def _get_kubeconform_binary(ctx):
    if ctx.attr.kubeconform:
        return ctx.executable.kubeconform
    toolchain = ctx.toolchains["@kubeconform.bzl//:toolchain_type"]
    if not toolchain:
        fail("No kubeconform toolchain found.")
    return toolchain.kubeconform_info.kubeconform_binary

def _kubeconform_test_impl(ctx):
    kubeconform_binary = _get_kubeconform_binary(ctx)
    manifests = ctx.files.data
    schema_files = ctx.files.schemas

    args = ["-strict"]
    if ctx.attr.kubernetes_version:
        args.extend(["-kubernetes-version", ctx.attr.kubernetes_version])
    # -skip requires comma-separated values; multiple -skip flags only use the last one
    if ctx.attr.skip_kinds:
        args.extend(["-skip", ",".join(ctx.attr.skip_kinds)])
    if ctx.attr.ignore_missing_schemas:
        args.append("-ignore-missing-schemas")

    if ctx.attr.schema_locations:
        for loc in ctx.attr.schema_locations:
            args.extend(["-schema-location", loc])

    # Add kubernetes core schemas directory (vendored, no network needed)
    k8s_schema_files = ctx.files.kubernetes_schemas
    if k8s_schema_files:
        k8s_schema_dir = _get_schema_dir(k8s_schema_files[0].short_path)
        args.extend(["-schema-location", k8s_schema_dir + "/{{ .ResourceKind }}{{ .KindSuffix }}.json"])

    # Add schema files directory as a schema-location using kubeconform's template syntax.
    # Schema files are named: {group}_{version}_{kind}.json (all lowercase)
    # which matches the template: {{ .Group }}_{{ .ResourceAPIVersion }}_{{ .ResourceKind }}.json
    if schema_files:
        # All schema files share the same directory in the runfiles tree
        schema_dir = _get_schema_dir(schema_files[0].short_path)
        args.extend(["-schema-location", schema_dir + "/{{ .Group }}_{{ .ResourceAPIVersion }}_{{ .ResourceKind }}.json"])

    args_str = " ".join(['"{}"'.format(a) for a in args])
    manifests_str = " ".join(['"{}"'.format(m.short_path) for m in manifests])

    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = script,
        content = """#!/bin/bash
set -euo pipefail
echo "Validating manifests with kubeconform..."
"{kubeconform}" {args} {manifests}
echo "Validation passed."
""".format(kubeconform = kubeconform_binary.short_path, args = args_str, manifests = manifests_str),
        is_executable = True,
    )

    return [DefaultInfo(executable = script, runfiles = ctx.runfiles(files = [kubeconform_binary] + manifests + schema_files + k8s_schema_files))]

_kubeconform_test = rule(
    implementation = _kubeconform_test_impl,
    attrs = {
        "data": attr.label_list(allow_files = [".yaml", ".yml", ".json"], mandatory = True),
        "schemas": attr.label_list(allow_files = [".json"]),
        "kubernetes_schemas": attr.label_list(allow_files = [".json"]),
        "kubernetes_version": attr.string(),
        "skip_kinds": attr.string_list(),
        "ignore_missing_schemas": attr.bool(default = False),
        "schema_locations": attr.string_list(),
        "kubeconform": attr.label(executable = True, cfg = "exec"),
    },
    test = True,
    toolchains = [config_common.toolchain_type("@kubeconform.bzl//:toolchain_type", mandatory = False)],
)

def _expect_kubeconform_failure_impl(ctx):
    kubeconform_binary = _get_kubeconform_binary(ctx)
    manifests = ctx.files.data
    schema_files = ctx.files.schemas

    args = ["-strict"]
    if ctx.attr.kubernetes_version:
        args.extend(["-kubernetes-version", ctx.attr.kubernetes_version])
    # -skip requires comma-separated values; multiple -skip flags only use the last one
    if ctx.attr.skip_kinds:
        args.extend(["-skip", ",".join(ctx.attr.skip_kinds)])
    if ctx.attr.ignore_missing_schemas:
        args.append("-ignore-missing-schemas")
    if ctx.attr.schema_locations:
        for loc in ctx.attr.schema_locations:
            args.extend(["-schema-location", loc])

    k8s_schema_files = ctx.files.kubernetes_schemas
    if k8s_schema_files:
        k8s_schema_dir = _get_schema_dir(k8s_schema_files[0].short_path)
        args.extend(["-schema-location", k8s_schema_dir + "/{{ .ResourceKind }}{{ .KindSuffix }}.json"])
    if schema_files:
        schema_dir = _get_schema_dir(schema_files[0].short_path)
        args.extend(["-schema-location", schema_dir + "/{{ .Group }}_{{ .ResourceAPIVersion }}_{{ .ResourceKind }}.json"])

    args_str = " ".join(['"{}"'.format(a) for a in args])
    manifests_str = " ".join(['"{}"'.format(m.short_path) for m in manifests])

    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = script,
        content = """#!/bin/bash
set -euo pipefail
if "{kubeconform}" {args} {manifests}; then
    echo "ERROR: kubeconform should have rejected the invalid manifest but it passed"
    exit 1
fi
echo "OK: kubeconform correctly rejected the invalid manifest"
""".format(kubeconform = kubeconform_binary.short_path, args = args_str, manifests = manifests_str),
        is_executable = True,
    )

    return [DefaultInfo(executable = script, runfiles = ctx.runfiles(files = [kubeconform_binary] + manifests + schema_files + k8s_schema_files))]

_expect_kubeconform_failure_test = rule(
    implementation = _expect_kubeconform_failure_impl,
    attrs = {
        "data": attr.label_list(allow_files = [".yaml", ".yml", ".json"], mandatory = True),
        "schemas": attr.label_list(allow_files = [".json"]),
        "kubernetes_schemas": attr.label_list(allow_files = [".json"]),
        "kubernetes_version": attr.string(),
        "skip_kinds": attr.string_list(),
        "ignore_missing_schemas": attr.bool(default = False),
        "schema_locations": attr.string_list(),
        "kubeconform": attr.label(executable = True, cfg = "exec"),
    },
    test = True,
    toolchains = [config_common.toolchain_type("@kubeconform.bzl//:toolchain_type", mandatory = False)],
)

def expect_kubeconform_failure(
        name,
        tags = [],
        schemas = [],
        kubernetes_schemas = ["@kubernetes_schemas//:schemas"],
        kubernetes_version = "1.33.5",
        **kwargs):
    """Test that expects kubeconform to reject the given manifests."""
    _expect_kubeconform_failure_test(
        name = name,
        tags = tags,
        schemas = schemas,
        kubernetes_schemas = kubernetes_schemas,
        kubernetes_version = kubernetes_version,
        **kwargs
    )

def kubeconform_test(
        name,
        tags = [],
        schemas = [],
        kubernetes_schemas = ["@kubernetes_schemas//:schemas"],
        kubernetes_version = "1.33.5",
        **kwargs):
    """Validates Kubernetes manifests using kubeconform.

    Args:
        name: Name of the test target
        tags: Additional tags
        schemas: JSON schema files for CRD validation
        kubernetes_schemas: Core Kubernetes JSON schemas (default: @kubernetes_schemas//:schemas)
        kubernetes_version: Kubernetes version for schema validation (default: 1.33.5)
        **kwargs: Arguments passed to the underlying rule (data, schema_locations, etc.)
    """
    _kubeconform_test(
        name = name,
        tags = tags,
        schemas = schemas,
        kubernetes_schemas = kubernetes_schemas,
        kubernetes_version = kubernetes_version,
        **kwargs
    )
