"""Rule for converting CRD YAML to JSON schema files."""

def _openapi2jsonschema_impl(ctx):
    outputs = ctx.outputs.outs
    args = ctx.actions.args()
    args.add("--output-dir", outputs[0].dirname)
    args.add_all(ctx.files.src)
    ctx.actions.run(
        executable = ctx.executable._tool,
        arguments = [args],
        inputs = ctx.files.src,
        outputs = outputs,
    )
    return [DefaultInfo(files = depset(outputs))]

_openapi2jsonschema = rule(
    implementation = _openapi2jsonschema_impl,
    attrs = {
        "src": attr.label(allow_files = True, mandatory = True),
        "outs": attr.output_list(mandatory = True),
        "_tool": attr.label(
            default = "//cmd/openapi2jsonschema",
            executable = True,
            cfg = "exec",
        ),
    },
)

def openapi2jsonschema(name, src, out = None, outs = [], **kwargs):
    """Converts CRD YAML files to JSON schema files.

    Args:
        name: Target name.
        src: CRD YAML file label.
        out: Single output file (use for single-schema CRDs).
        outs: Multiple output files (use for multi-version CRDs).
        **kwargs: Additional arguments passed to the rule.
    """
    _openapi2jsonschema(
        name = name,
        src = src,
        outs = outs if outs else [out],
        **kwargs
    )
