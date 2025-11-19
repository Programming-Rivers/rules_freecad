"""
Defines a Bazel module extension that can be used in MODULE.bazel files.

This extensios allows the line
```
custom_python_extension = use_extension("//tools:extensions.bzl", "custom_python_extension")
```
in the MODULE.bazel file to work.
"""

load("//tools:py_distrubution.bzl", "py_distribution")

def _custom_python_extension_impl(module_ctx):
    py_distribution(
        name = "python_interpreter_linux_x86_64",
        interpreter_label = "@@//:freecad_extracted_linux",
        files_label = "@@//:freecad_extracted_linux",
    )

    py_distribution(
        name = "python_interpreter_macos_arm64",
        interpreter_label = "@@//:freecad_extracted_macos",
        files_label = "@@//:freecad_extracted_macos",
    )

custom_python_extension = module_extension(
    implementation = _custom_python_extension_impl,
)
