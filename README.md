# kubeconform.bzl

Bazel rules for validating Kubernetes manifests using [kubeconform](https://github.com/yannh/kubeconform).

## Setup

Add the following to your `MODULE.bazel`:

```starlark
bazel_dep(name = "kubeconform.bzl", version = "0.1.0")

kubeconform = use_extension("@kubeconform.bzl//kubeconform:extensions.bzl", "kubeconform")
kubeconform.toolchain(version = "0.6.7")  # Optional: uses latest if omitted
kubeconform.kubernetes_schemas(kubernetes_version = "1.33.5")
use_repo(kubeconform, "kubeconform_toolchains", "kubernetes_schemas")

register_toolchains("@kubeconform_toolchains//:all")
```

## Usage

### Basic Manifest Validation

```starlark
load("@kubeconform.bzl//:kubeconform.bzl", "kubeconform_test")

kubeconform_test(
    name = "deployment_test",
    data = ["deployment.yaml"],
)
```

### CRD Validation

Convert CRD YAML to JSON schema and validate custom resources:

```starlark
load("@kubeconform.bzl//:kubeconform.bzl", "kubeconform_test", "openapi2jsonschema")

# Generate JSON schema from CRD
openapi2jsonschema(
    name = "my_crd_schema",
    src = "my_crd.yaml",
    outs = ["mygroup.example.com_v1_myresource.json"],
)

# Validate custom resource against the generated schema
kubeconform_test(
    name = "my_resource_test",
    data = ["my_resource.yaml"],
    kubernetes_schemas = [],  # Skip core K8s schemas
    schemas = [":my_crd_schema"],
)
```

### Expect Validation Failure

Test that invalid manifests are correctly rejected:

```starlark
load("@kubeconform.bzl//:kubeconform.bzl", "expect_kubeconform_failure")

expect_kubeconform_failure(
    name = "invalid_manifest_test",
    data = ["invalid.yaml"],
)
```

### Custom Options

```starlark
kubeconform_test(
    name = "manifest_test",
    data = ["manifest.yaml"],
    kubernetes_version = "1.31.0",
    skip_kinds = ["CustomResourceDefinition"],
    ignore_missing_schemas = True,
    schema_locations = ["https://example.com/schemas/{{ .ResourceKind }}.json"],
)
```

### Custom Kubeconform Binary

If you prefer to use your own kubeconform binary (e.g., compiled from source via `go_deps`):

```starlark
kubeconform_test(
    name = "manifest_test",
    data = ["manifest.yaml"],
    kubeconform = "@com_github_yannh_kubeconform//cmd/kubeconform",
)
```

### Compiled Kubeconform Toolchain

For hermetic builds, you can compile kubeconform from Go source and register it as a toolchain:

```starlark
# BUILD file
load("@kubeconform.bzl//:kubeconform.bzl", "kubeconform_toolchain")

kubeconform_toolchain(
    name = "compiled_kubeconform_toolchain",
    kubeconform = "@com_github_yannh_kubeconform//cmd/kubeconform",
)

toolchain(
    name = "kubeconform_toolchain",
    toolchain = ":compiled_kubeconform_toolchain",
    toolchain_type = "@kubeconform.bzl//:toolchain_type",
)
```

```starlark
# MODULE.bazel
register_toolchains("//:kubeconform_toolchain")
```

See the [hermetic example](examples/hermetic/) for a complete setup with `rules_go` and `gazelle`.

## Rules

### `kubeconform_test`

Validates Kubernetes manifests against JSON schemas.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `data` | label_list | required | YAML/JSON manifest files to validate |
| `schemas` | label_list | `[]` | Custom JSON schema files for CRD validation |
| `kubernetes_schemas` | label_list | `["@kubernetes_schemas//:schemas"]` | Core Kubernetes JSON schemas |
| `kubernetes_version` | string | `"1.33.5"` | Kubernetes version for schema validation |
| `skip_kinds` | string_list | `[]` | Resource kinds to skip |
| `ignore_missing_schemas` | bool | `False` | Ignore resources without schemas |
| `schema_locations` | string_list | `[]` | Additional schema location URLs |
| `kubeconform` | label | `None` | Custom kubeconform binary (uses toolchain if not set) |

### `expect_kubeconform_failure`

Test that expects kubeconform to reject the given manifests. Same attributes as `kubeconform_test`.

### `openapi2jsonschema`

Converts CRD YAML files to JSON schema files.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `src` | label | required | CRD YAML file |
| `out` | string | `None` | Single output file (for single-version CRDs) |
| `outs` | string_list | `[]` | Multiple output files (for multi-version CRDs) |

### `kubeconform_toolchain`

Defines a kubeconform toolchain for use with `register_toolchains`.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `kubeconform` | label | required | The kubeconform binary |

## Examples

- [simple example](examples/simple/) - Basic manifest and CRD validation
- [hermetic example](examples/hermetic/) - Compile kubeconform from Go source and register as toolchain

## Running Tests

```bash
bazel test //:deployment_test
```

## License

Apache-2.0
