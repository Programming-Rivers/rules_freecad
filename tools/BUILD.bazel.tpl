"""
Turns FreeCAD into a drop-in replacement for a standard Python interpreter in the Bazel build system.

The drop-in replacement maintains all the proper Bazel toolchain conventions.

The key role of this template is to:
* Define how FreeCAD should be used as a Python interpreter
* Make all necessary files available to the runtime
* Configure the toolchain to work with Bazel's Python rules
* Allow platform-specific constraints to be injected during toolchain registration

"""

load(
    "@rules_python//python:defs.bzl",
    "py_runtime",
    "py_runtime_pair",
)

# Point to the extracted binary within the FreeCAD archive
py_runtime(
    name = "py_runtime",
    files = [
        "{files_label}",
    ],
    interpreter = "{interpreter_label}",
    python_version = "PY3",
)

# Only use python verison 3:
py_runtime_pair(
    name = "py_runtime_pair",
    py3_runtime = ":py_runtime",
)

toolchain(
    name = "freecad_toolchain",
    exec_compatible_with = [
        {constraints},
    ],
    target_compatible_with = [
        {constraints},
    ],
    toolchain = ":py_runtime_pair",
    toolchain_type = "@rules_python//python:toolchain_type",
)
