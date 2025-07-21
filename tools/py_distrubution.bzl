"""
Bootstrapps the mechanism that makes FreeCAD available as a Python toolchain in the Bazel build system.
"""

def _py_distribution_impl(repository_ctx):
    """Implementation of the py_distribution rule."""
    appimage_path = repository_ctx.path(repository_ctx.attr.name + ".AppImage")
    download_result = repository_ctx.download(
        url = repository_ctx.attr.url,
        output = appimage_path,
        sha256 = repository_ctx.attr.sha256,
        executable = True,
    )
    if not download_result.success:
        fail("Failed to download the FreeCAD AppImage from %s to %s", repository_ctx.attr.url, appimage_path)
    extract_result = repository_ctx.execute([appimage_path, "--appimage-extract"])
    if extract_result.return_code != 0:
        fail(
            "Failed to extrat the FreeCAD binary from %s uisg the --appimaeg-extract flag (return code %d): %s %s",
            extract_result.return_code,
            extract_result.stdout,
            extract_result.stderr,
        )
    constraints = [
        '"@platforms//os:linux"',
        '"@platforms//cpu:x86_64"',
        '"@rules_freecad//platforms:freecad_1.0.x"',
    ]

    repository_ctx.template(
        "BUILD.bazel",
        Label("//tools:BUILD.bazel.tpl"),
        substitutions = {
            "{constraints}": ", ".join(constraints),
        },
    )

py_distribution = repository_rule(
    implementation = _py_distribution_impl,
    attrs = {
        "url": attr.string(mandatory = True, doc = "URL of the FreeCAD AppImage."),
        "sha256": attr.string(mandatory = True, doc = "SHA256 checksum of the AppImage."),
    },
)
