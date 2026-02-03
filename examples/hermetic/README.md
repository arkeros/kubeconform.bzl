# kubeconform.bzl Hermetic Kubeconform Toolchain Example

This example demonstrates how to use a **compiled kubeconform binary** as a toolchain instead of the pre-built binaries. The kubeconform binary is compiled from Go source using `rules_go` and `gazelle`, then registered as a toolchain.

## When to use a compiled kubeconform toolchain

Use this approach when you need:

- **Hermetic builds**: Kubeconform binary compiled from source within Bazel
- **Custom patches**: Apply modifications to kubeconform source code
- **Go monorepo integration**: Consistent dependency management with existing Go code
- **Reproducibility**: Full control over the exact kubeconform version and build

## Usage

Build and run the deployment validation test:

```bash
bazel test //:deployment_test
```

Build and run the CRD validation test:

```bash
bazel test //:widget_test
```

Run all tests:

```bash
bazel test //...
```

## How it works

1. **Go dependencies**: `go.mod` declares kubeconform as a dependency
2. **Gazelle extension**: `go_deps.from_file()` imports Go dependencies
3. **Define toolchain**: `kubeconform_toolchain` rule wraps the compiled binary
4. **Register toolchain**: `register_toolchains("//:kubeconform_toolchain")` in MODULE.bazel
5. **Validate manifests**: `kubeconform_test` automatically uses the registered toolchain

## Key difference from pre-built toolchain

Instead of downloading a pre-built binary:

```starlark
# Pre-built approach (downloads binary)
kubeconform = use_extension("@kubeconform.bzl//kubeconform:extensions.bzl", "kubeconform")
kubeconform.toolchain(version = "0.6.7")
use_repo(kubeconform, "kubeconform_toolchains")
register_toolchains("@kubeconform_toolchains//:all")
```

This example compiles from source and registers the toolchain:

```starlark
# In BUILD file - define toolchain with compiled binary
kubeconform_toolchain(
    name = "compiled_kubeconform_toolchain",
    kubeconform = "@com_github_yannh_kubeconform//cmd/kubeconform",
)

toolchain(
    name = "kubeconform_toolchain",
    toolchain = ":compiled_kubeconform_toolchain",
    toolchain_type = "@kubeconform.bzl//:toolchain_type",
)

# In MODULE.bazel - register the toolchain
register_toolchains("//:kubeconform_toolchain")
```

Then `kubeconform_test` rules work without any explicit `kubeconform` attribute:

```starlark
kubeconform_test(
    name = "deployment_test",
    data = ["deployment.yaml"],
    # No kubeconform attribute needed - uses registered toolchain
)
```

## Dev environment

This example uses [`lazy_bazel_env`](https://github.com/arkeros/lazy_bazel_env.bzl) to provide hermetic dev tools. Both `go` and `kubeconform` are automatically available via `GO_TOOLS` since they're declared in `go.mod`:

```bash
bazel run //tools:dev
direnv allow
go version        # hermetic Go from rules_go
kubeconform -v    # compiled from source
```

The `GO_TOOLS` dictionary from `@gazelle//:go_tools.bzl` automatically exposes `go` and all Go binaries declared in `go.mod` (packages under `tool` directive or with `/cmd/` paths).
