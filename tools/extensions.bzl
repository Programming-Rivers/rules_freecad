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
        url = "https://github.com/FreeCAD/FreeCAD/releases/download/1.0.2/FreeCAD_1.0.2-conda-Linux-x86_64-py311.AppImage",
        sha256 = "e00be00ad9fdb12b05c5002bfd1aa2ea8126f2c1d4e2fb603eb7423b72904f61",
    )

custom_python_extension = module_extension(
    implementation = _custom_python_extension_impl,
)
