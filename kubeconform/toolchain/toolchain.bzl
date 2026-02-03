"""Kubeconform toolchain definition."""

KubeconformInfo = provider(
    doc = "Information about the kubeconform binary.",
    fields = {
        "kubeconform_binary": "The kubeconform executable File.",
    },
)

def _kubeconform_toolchain_impl(ctx):
    kubeconform_files = ctx.attr.kubeconform.files.to_list()
    if len(kubeconform_files) == 0:
        fail("kubeconform attribute must provide at least one file")

    kubeconform_binary = kubeconform_files[0]
    kubeconform_info = KubeconformInfo(kubeconform_binary = kubeconform_binary)

    default_info = DefaultInfo(
        files = depset(kubeconform_files),
        runfiles = ctx.runfiles(files = kubeconform_files),
    )

    template_variables = platform_common.TemplateVariableInfo({
        "KUBECONFORM_BIN": kubeconform_binary.path,
    })

    toolchain_info = platform_common.ToolchainInfo(
        kubeconform_info = kubeconform_info,
        template_variables = template_variables,
        default = default_info,
    )

    return [default_info, toolchain_info, template_variables]

kubeconform_toolchain = rule(
    implementation = _kubeconform_toolchain_impl,
    attrs = {
        "kubeconform": attr.label(
            mandatory = True,
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
    },
    provides = [DefaultInfo, platform_common.ToolchainInfo, platform_common.TemplateVariableInfo],
)
