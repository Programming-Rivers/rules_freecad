"""
Rule for extracting FreeCAD archives.
"""

def _extract_freecad_impl(ctx):
    output_dir = ctx.actions.declare_directory(ctx.attr.name + "_dir")
    wrapper_script = ctx.actions.declare_file(ctx.attr.name + "_wrapper")

    if ctx.attr.os == "linux":
        # Linux AppImage extraction
        # We need to copy the AppImage to a temp file to execute it
        # We use a shell command to handle the extraction

        command = """
        cp {src} freecad.AppImage
        chmod +x freecad.AppImage
        ./freecad.AppImage --appimage-extract > /dev/null
        mv squashfs-root/* {out_dir}/
        
        # Remove dangling symlinks
        find {out_dir} -xtype l -delete
        
        # Create wrapper
        echo '#!/bin/bash' > {wrapper}
        echo 'DIR=$(dirname $(realpath $0))/{dir_name}' >> {wrapper}
        echo 'exec $DIR/usr/bin/freecadcmd "$@"' >> {wrapper}
        chmod +x {wrapper}
        """.format(
            src = ctx.file.src.path,
            out_dir = output_dir.path,
            wrapper = wrapper_script.path,
            dir_name = output_dir.basename,
        )

        ctx.actions.run_shell(
            inputs = [ctx.file.src],
            outputs = [output_dir, wrapper_script],
            command = command,
            mnemonic = "ExtractFreeCADLinux",
        )

    elif ctx.attr.os == "macos":
        # MacOS DMG extraction using 7zip
        tool = ctx.executable.tool

        command = """
        {tool} x {src} -o{out_dir} > /dev/null
        
        # Remove dangling symlinks
        find {out_dir} -xtype l -delete
        
        # Create wrapper
        echo '#!/bin/bash' > {wrapper}
        echo 'DIR=$(dirname $(realpath $0))/{dir_name}' >> {wrapper}
        echo 'exec $DIR/FreeCAD/FreeCAD.app/Contents/MacOS/FreeCADCmd "$@"' >> {wrapper}
        chmod +x {wrapper}
        """.format(
            tool = tool.path,
            src = ctx.file.src.path,
            out_dir = output_dir.path,
            wrapper = wrapper_script.path,
            dir_name = output_dir.basename,
        )

        ctx.actions.run_shell(
            inputs = [ctx.file.src],
            tools = [tool],
            outputs = [output_dir, wrapper_script],
            command = command,
            mnemonic = "ExtractFreeCADMacOS",
        )

    return [
        DefaultInfo(
            files = depset([output_dir, wrapper_script]),
            runfiles = ctx.runfiles(files = [output_dir, wrapper_script]),
            executable = wrapper_script,
        ),
        OutputGroupInfo(
            wrapper = depset([wrapper_script]),
            directory = depset([output_dir]),
        ),
    ]

extract_freecad = rule(
    implementation = _extract_freecad_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
        "tool": attr.label(allow_single_file = True, executable = True, cfg = "exec"),
        "os": attr.string(values = ["linux", "macos"], mandatory = True),
    },
    executable = True,
)
