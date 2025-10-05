# rules_freecad: A Proof of Concept for FreeCAD Scripting with Bazel

This repository is a proof of concept demonstrating how to
integrate FreeCAD's scripting capabilities with the Bazel build system.
The goals are to:
*   Simplify the FreeCAD scripting workflow to be as familiar as writing regular Python code.
*   Abstract away FreeCAD internals, like `freecadcmd` and headless mode, from the end-user.
*   Leverage Bazel's hermetic toolchain and platform capabilities to create reproducible, self-contained FreeCAD-based workflows.

The core idea is to treat the FreeCAD AppImage not just as an application but as a complete,
pre-packaged Python distribution.
By doing this, we can define a Bazel Python toolchain that uses FreeCAD's embedded Python interpreter,
giving build targets access to the full FreeCAD API in a hermetic and predictable way.

This project serves as a foundation for building a more comprehensive `rules_freecad` ruleset,
which would simplify using FreeCAD for automated design, manufacturing, and testing tasks.

## Success Criteria

This proof of concept is successful if a user can switch between regular Python scripting and FreeCAD scripting
as easily and conveniently as they can switch between different versions of Python.

Concretely, a user should be able to configure a project to use the FreeCAD toolchain with a similar amount of effort
(e.g., under 20 lines of configuration) as it takes to switch between different standard Python versions.

While this proof of concept does not need to implement every Bazel feature,
it must demonstrate a clear path for supporting them in the future, including:

*   **Cross-Platform Support**:
    The ability to build and run on any operating system (Windows, macOS, Linux) and CPU architecture (x86_64, ARM64).
*   **Fine-Grained Dependencies**:
    The ability to define libraries, declare dependencies between them, and track inputs and outputs
    for correct, incremental builds.
*   **Hermeticity**: Ensuring that a given set of inputs always produces the exact same output,
    regardless of the machine, workspace state, or time of day.
*   **Performance**: Enabling high-performance, incremental builds through caching and parallel execution.
*   **Tooling Integration**: Demonstrating that the rich ecosystem of standard Python tooling
    (linters, formatters, debuggers, LSP) can be applied to FreeCAD scripting.

## Core Concepts

### Hermetic Toolchains with Bazel

Modern software development requires builds to be reproducible and insulated from the host system's configuration.
Bazel achieves this through **hermetic toolchains**.
Instead of relying on a Python interpreter found on the system `PATH`,
a hermetic toolchain fetches a specific, versioned Python distribution.

This project applies the hermetic toolchain concept to FreeCAD.
The FreeCAD AppImage bundles a specific version of Python
along with all the necessary libraries and the FreeCAD modules themselves.
Defining a toolchain that points to this distribution ensures that any script that needs the FreeCAD API
runs against the exact same environment, every time, on any machine.

## Usage Example

Imagine a user wants to run the following FreeCAD script:

**`test/main.py`**
```python
"""Test if the FreeCAD toolchain is used"""
import sys

# Importing FreeCAD only works if this script is run with FreeCAD's bundled python
import FreeCAD as App

print("Hello from FreeCAD's Python! You are using the FreeCAD Python interpreter:")
print(f"Python executable: {sys.executable}")
print(f"Python version: {sys.version}")
```

A user needs to perform two steps to instruct Bazel to use FreeCAD's built-in Python for this script:

1.  **Set the Target Platform:**
    In the `BUILD.bazel` file, use the `target_compatible_with` attribute to tell Bazel
    that this script requires the custom FreeCAD platform.

    **`test/BUILD.bazel`**
    ```python
    load("@rules_python//python:defs.bzl", "py_binary")

    # This target must be built with the FreeCAD Python toolchain
    py_binary(
        name = "main_app",
        srcs = ["main.py"],
        # This constraint ensures Bazel selects the custom FreeCAD toolchain
        target_compatible_with = ["//platforms:freecad_1.0.x"],
    )
    ```

2.  **Register the Toolchain:**
    In the `MODULE.bazel` file, register the FreeCAD toolchain and execution platform.
    This makes them available to Bazel's toolchain resolution process.

    **`MODULE.bazel`**
    ```python
    # Assumes `rules_freecad` is a dependency
    # ...

    # Use the extension from rules_freecad to create the toolchain repository
    custom_python_extension = use_extension(
        "//tools:extensions.bzl",
        "custom_python_extension",
    )
    use_repo(custom_python_extension, "python_interpreter_linux_x86_64")

    # Register the toolchain so Bazel can find it
    register_toolchains("@python_interpreter_linux_x86_64//:freecad_toolchain")

    # Register the platform for executing FreeCAD actions
    register_execution_platforms(
        "//platforms:freecad_linux_x86_64",
    )
    ```

## How It Works

Bazel uses the FreeCAD toolchain through several layers of its module and platform frameworks.
This process is transparent to the end-user:

1.  **Fetching FreeCAD**:
    A `module_extension` downloads the specified FreeCAD AppImage using a custom repository rule.
2.  **Extracting the Toolchain**:
    The rule executes the AppImage with the `--appimage-extract` flag, unpacking it into a `squashfs-root` directory
    and exposing the internal Python interpreter (`usr/bin/freecadcmd`).
3.  **Generating the BUILD file**:
    The rule generates a `BUILD.bazel` file from a template,
    defining the necessary targets to make the extracted contents usable by Bazel.
4.  **Defining the `py_runtime`**:
    The generated `BUILD.bazel` file defines a `py_runtime` target.
    This tells `rules_python` that a Python interpreter exists at `squashfs-root/usr/bin/freecadcmd`.
5.  **Defining the Platform**:
    A custom `constraint_value` (`:freecad_1.0.x`) is created to uniquely identify this toolchain.
    This is combined with OS and CPU constraints into a `platform` target.
6.  **Toolchain Registration**:
    The `register_toolchains` function makes the FreeCAD Python toolchain available to Bazel.
    When a target requests a Python interpreter and is constrained to the `:freecad_1.0.x` platform,
    Bazel automatically selects this toolchain.

### Running the Example

To build and run the test application, execute the following command.
The `--platforms` flag instructs Bazel which platform to target,
ensuring the correct toolchain is selected.

```bash
bazel run //test:main_app --platforms=//platforms:freecad_linux_x86_64
```

You should see output similar to this, confirming that the script was executed by `freecadcmd`:

```
Hello from FreeCAD's Python! You are using the FreeCAD Python interpreter:
Python executable: /path/to/your/bazel/cache/.../squashfs-root/usr/bin/freecadcmd
Python version: 3.11.13 | packaged by conda-forge | (main, Jun 4 2025, 15:08:00) [GCC 13.3.0]
```

## Project Vision

This repository is the first step toward a complete `rules_freecad` Bazel ruleset.
The ultimate vision is to create make FreeCAD scripting as convenient as python scripting,
making all the Python development tools in Bazel available for parametric CAD with FreeCAD into automated workflows

Imagine features like this:

* Debugging a Complex Script:
  - A user writes a FreeCAD script to generate a parametric model but encounters an error. Using the debugging tools,
  they step through the script, inspect the values of key parameters, and identify the issue.

* Cross-Platform Collaboration:
  - An engineer develops a FreeCAD script on their macOS laptop,
  iterates the script on a remote Linux workstation for performance,
  and deploys the final model to a Raspberry Pi for on-site testing.

* Automated Regression Testing:
  - A team uses rules_freecad to validate that changes to a parametric model do not break downstream workflows,
  such as exporting to STEP files or running simulations.

* Custom Export Pipelines:
  - A user defines a custom Bazel rule to export FreeCAD models to a specific format,
  ensuring that the export process is reproducible and integrated into their CI/CD pipeline.

* Interactive Model Exploration:
  - A designer uses the LSP integration to explore FreeCAD's API,
  quickly finding the functions and classes they need to modify a model.

Fortunately, Bazel provides the crucial fundamental parts required for this vision.
This proof of concept shows that this vision is attainable without requiring the creation of everything from the ground.
