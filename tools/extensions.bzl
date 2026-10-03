"""
Defines a Bazel module extension that can be used in MODULE.bazel files.

This extension allows the line
```
custom_python_extension = use_extension("//tools:extensions.bzl", "custom_python_extension")
```
in the MODULE.bazel file to work.
"""

load("//tools:py_distribution.bzl", "py_distribution")

def _custom_python_extension_impl(module_ctx):
    py_distribution(
        name = "python_interpreter_linux_x86_64",
        interpreter_label = str(Label("//:freecad_extracted_linux")),
        files_label = str(Label("//:freecad_extracted_linux")),
        exec_constraints = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
        target_constraints = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
            str(Label("//platforms:freecad_1.1.x")),
        ],
    )

    py_distribution(
        name = "python_interpreter_macos_arm64",
        interpreter_label = str(Label("//:freecad_extracted_macos")),
        files_label = str(Label("//:freecad_extracted_macos")),
        exec_constraints = [
            "@platforms//os:macos",
            "@platforms//cpu:arm64",
        ],
        target_constraints = [
            "@platforms//os:macos",
            "@platforms//cpu:arm64",
            str(Label("//platforms:freecad_1.1.x")),
        ],
    )

custom_python_extension = module_extension(
    implementation = _custom_python_extension_impl,
)
