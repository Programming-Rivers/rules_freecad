"""
Bootstrapps the mechanism that makes FreeCAD available as a Python toolchain in the Bazel build system.
"""

def _py_distribution_impl(repository_ctx):
    """Implementation of the py_distribution rule."""
    # Extraction is now handled by a genrule in the main repository.
    # This rule only generates the toolchain definition.

    exec_constraints = [
        '"@platforms//os:linux"',
        '"@platforms//cpu:x86_64"',
    ]
    target_constraints = exec_constraints + [
        repr(str(Label("//platforms:freecad_1.0.x"))),
    ]

    if "macos" in repository_ctx.name:
        exec_constraints = [
            '"@platforms//os:macos"',
            '"@platforms//cpu:arm64"',
        ]
        target_constraints = exec_constraints + [
            repr(str(Label("//platforms:freecad_1.0.x"))),
        ]

    repository_ctx.template(
        "BUILD.bazel",
        Label("//tools:BUILD.bazel.tpl"),
        substitutions = {
            "{exec_constraints}": ", ".join(exec_constraints),
            "{target_constraints}": ", ".join(target_constraints),
            "{interpreter_label}": repository_ctx.attr.interpreter_label,
            "{files_label}": repository_ctx.attr.files_label,
        },
    )

py_distribution = repository_rule(
    implementation = _py_distribution_impl,
    attrs = {
        "interpreter_label": attr.string(mandatory = True, doc = "Label to the interpreter binary."),
        "files_label": attr.string(mandatory = True, doc = "Label to the filesgroup."),
    },
)
