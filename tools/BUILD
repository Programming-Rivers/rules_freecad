"""
Declares a new toolchain type that Bazel can use to identify and select the custom Python toolchain based on FreeCAD.

Define the interface (toolchain_type) that the custom python toolchain implements
Register the toolchain with Bazel's toolchain resolution system.
Specify the platform constraints that determine when this toolchain should be selected.
Make the toolchain available to other parts of the build.
"""

package(default_visibility = ["//visibility:public"])

toolchain_type(
    name = "toolchain_type",
    visibility = [
        "//visibility:public",
    ],
)

toolchain(
    name = "freecad_python_linux_x86_64",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
        "//platforms:freecad_1.0.x",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
        "//platforms:freecad_1.0.x",
    ],
    toolchain = ":freecad_py_linux_x86_64",
    toolchain_type = ":toolchain_type",
    visibility = [
        "//visibility:public",
    ],
)
