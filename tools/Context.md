# Architecting Modern, Hermetic Python Toolchains in Bazel


## Introduction: Beyond Vanilla Builds - The Imperative for Hermetic, Custom Toolchains

In the landscape of modern software development, the complexity of build systems has grown in lockstep with the scale and diversity of codebases. The challenge is no longer merely compiling code but ensuring that the entire build process is correct, reproducible, secure, and efficient across heterogeneous environments. At the heart of this challenge lies the concept of hermeticity: the principle that a build should be self-contained, insulated from the host system's tools and libraries, guaranteeing that the same source code produces the same output, every time, on any machine.1 This report provides a definitive guide to achieving hermeticity for Python projects within the Bazel build system by defining a custom toolchain.
The default, autodetecting toolchains provided by many build systems, including early versions of Bazel, often undermine this goal. They rely on the host machine's environment, such as the Python interpreter found in the system's $PATH, creating a source of non-determinism and "works on my machine" failures.1 The solution is to define a custom toolchain that fetches a specific, pre-packaged Python distribution, complete with required libraries, ensuring every developer and CI agent uses an identical environment.
Navigating Bazel's own evolution is a critical aspect of this task. Bazel is a powerful but rapidly changing ecosystem, and this has led to a landscape where official documentation, community examples, and AI-generated suggestions can be a minefield of outdated practices.2 Concepts like the
WORKSPACE file and language-specific configuration flags, while once central to Bazel, are now deprecated and on a clear path to removal. This report serves as a map through this evolving terrain, focusing exclusively on the modern, future-proof paradigms that are the cornerstones of Bazel from version 7 onwards: the Bzlmod external dependency system and the unified platforms and toolchains framework. By understanding these core concepts and their historical context, teams can provide precise, correct instructions to any coding assistant, enabling the creation of robust, maintainable, and truly hermetic build systems.

## Section 1: The Modern Bazel Paradigm: Declarative Dependencies and Platform-Driven Configuration

To construct a modern toolchain in Bazel, one must first understand the two foundational pillars upon which it is built: a declarative dependency management system and a standardized framework for describing build environments. These two systems represent a strategic shift away from the imperative and often fragile configurations of the past, towards a more robust, scalable, and maintainable approach.

1.1 From WORKSPACE to MODULE.bazel: A Revolution in Dependency Management

The most significant evolution in modern Bazel is the transition from the legacy WORKSPACE system to Bzlmod. This is not merely a syntactic change but a fundamental rethinking of how external dependencies are managed.

The Legacy WORKSPACE System and Its Shortcomings

For many years, the WORKSPACE file was the entry point for a Bazel project, responsible for defining all external dependencies.4 This system, however, was fraught with inherent problems that became more acute as projects grew in complexity:
Imperative and Order-Dependent: The WORKSPACE file was evaluated sequentially, like a script. The order in which repository rules like http_archive were declared mattered. This led to the infamous "diamond dependency" problem: if module A depends on B and C, and B and C both depend on different versions of D, the version of D that gets used is determined simply by which dependency (B or C) is declared first in the root WORKSPACE file. This made dependency resolution unpredictable and fragile.5
Macro Limitations: A common pattern was for rule sets to provide a "deps" macro that users would call in their WORKSPACE to define transitive dependencies. However, these macros could not load other .bzl files, forcing rule authors to bundle all transitive dependency definitions into a single, monolithic macro or create complex, layered macros that were difficult for users to manage.5
Lack of True Version Resolution: The system lacked a formal mechanism for version selection. Dependencies were typically pinned to specific URLs and SHA256 hashes, with no way to negotiate compatible versions across the entire dependency graph.5

Introducing Bzlmod: The Declarative Future

Bzlmod, introduced in Bazel 5.0 and enabled by default since Bazel 7.0, was designed to solve these problems by introducing concepts from modern package managers.6 It operates on a declarative model centered around the
MODULE.bazel file:
Declarative Dependency Graph: Instead of imperatively fetching archives, a MODULE.bazel file declares its direct dependencies using bazel_dep(name = "...", version = "..."). Bazel reads the MODULE.bazel files of all transitive dependencies to construct a complete dependency graph.6
Version Resolution: Bzlmod implements a version resolution algorithm called Minimal Version Selection (MVS). For any given module in the dependency graph, Bzlmod selects the highest version requested by any dependent. This ensures that only a single version of each module exists in the final build, resolving the diamond dependency problem in a deterministic way.8
Decoupling with Module Extensions: Complex repository logic, such as fetching non-Bazel archives or running configuration scripts, is handled by module extensions. This isolates the side-effect-heavy process of defining repositories from the pure, declarative dependency graph, leading to a cleaner and more predictable system.4

The Inevitable Migration

The transition to Bzlmod is not optional; it is the designated future of Bazel. The official roadmap is explicit:
Bazel 7: Bzlmod is enabled by default. If a MODULE.bazel file is not present, an empty one is created. The legacy WORKSPACE system continues to function alongside it for migration purposes.7
Bazel 8: The WORKSPACE system is disabled by default.9
Bazel 9: All WORKSPACE functionality will be completely removed.9
This clear migration path underscores the critical importance of adopting a Bzlmod-centric approach for any new Bazel configuration. Instructing a coding assistant to use WORKSPACE for dependency management is functionally equivalent to writing code that will be broken by an upcoming major release.

1.2 Describing Environments: Platforms and Constraints

The second pillar of modern Bazel is the unified framework for describing build environments. This system replaces a chaotic collection of language-specific flags with a single, coherent model.

The Problem of Ad-Hoc Configuration

Historically, configuring Bazel for different target architectures or toolchains was a fragmented experience. C++ rules relied on a combination of --cpu, --compiler, and --crosstool_top to specify the target architecture and toolchain location. Java rules evolved their own independent flags like --java_toolchain, and Android had yet another set with --android_cpu. None of these systems interoperated, leading to awkward, incorrect, and difficult-to-maintain build configurations, especially in polyglot projects.11

The Unified Solution: Platforms

The platforms framework was introduced to solve this problem by creating a standardized, language-agnostic way to model build environments. It is composed of three core concepts 14:
constraint_setting: This defines a dimension or category in which environments can differ. For example, a constraint_setting could be created for "cpu_architecture", "operating_system", or "glibc_version".
constraint_value: This represents a specific choice for a given constraint_setting. For the "operating_system" setting, constraint_values might include "linux", "macos", and "windows". Together, a setting and its values effectively define an enum.
platform: This is a named collection of constraint_values that describes a concrete environment. For example, a platform named linux_x86_64 would be defined by the combination of the linux value for the os setting and the x86_64 value for the cpu setting.
This system allows build and rule authors to reason about environments in a structured way, moving configuration from opaque command-line flags to version-controllable BUILD files.

The Three Critical Platform Roles

To correctly model complex build scenarios like cross-compilation, Bazel recognizes that a platform can serve one of three distinct roles during a build 14:
Host Platform: The platform on which Bazel itself is running (e.g., a macOS developer machine).
Execution Platform: The platform where build actions, such as compilation and linking, are executed. This could be the same as the host platform for local builds, or a Linux container for remote builds.
Target Platform: The platform for which the final artifacts are intended (e.g., a Linux ARM64 server or an iOS device).
Understanding the distinction between these roles is fundamental to the toolchain resolution process, which must select tools that can run on the execution platform to produce artifacts that are compatible with the target platform.

Canonical Constraints

To prevent fragmentation where every project defines its own constraint_value for "linux", the Bazel team maintains the @platforms repository (github.com/bazelbuild/platforms). This repository provides canonical definitions for the most common operating systems and CPU architectures. Using these canonical constraints is strongly recommended, as it ensures that toolchains and libraries from different projects can interoperate based on a shared understanding of what constitutes a given platform.16
The evolution towards Bzlmod and the platforms framework is a deliberate move away from imperative, tightly-coupled configurations. The legacy systems required users to tell Bazel how to build by pointing it to specific tool paths and ordering dependencies manually. The modern paradigm is declarative: users tell Bazel what they need—a dependency on a module at a certain version, or a toolchain compatible with a specific target platform—and Bazel's internal logic is responsible for resolving those needs into a concrete build plan. This philosophical shift is the key to creating scalable, correct, and maintainable builds.

## Section 2: The Toolchain Resolution Framework: Bazel's Dependency Injection System

At the heart of Bazel's modern build configuration is the toolchain resolution framework. This system is what connects a rule's abstract need for a tool (like "a Python interpreter") to a concrete implementation (like "the custom Python 3.11.5 interpreter for Linux x86_64"). The framework is best understood as a form of compile-time dependency injection, where abstract interfaces are declared and concrete implementations are selected and "injected" based on platform constraints.17

2.1 The Core Components of a Toolchain

Defining and using a toolchain involves three primary components that work in concert: the type, the implementation, and the bridge that connects them.

toolchain_type: The Abstract Interface

A toolchain_type is a simple, unique target that serves as an abstract identifier for a class of tools. It acts as a contract or an interface. A rule that needs a compiler does not depend on a specific gcc or clang target; instead, it declares a dependency on a toolchain_type, such as //my_language:toolchain_type. This decouples the rule's logic from the specific tools used to satisfy its requirements.18 By convention, these targets are named
toolchain_type and are distinguished by their package path.

```
# //bar_tools/BUILD
# Defines the "interface" for a bar compiler toolchain.
toolchain_type(name = "toolchain_type")
```


The Language-Specific Rule and ToolchainInfo: The Implementation

The concrete implementation of a toolchain is provided by a language-specific rule, often suffixed with _toolchain by convention (e.g., py_runtime_pair, cc_toolchain). This rule is responsible for gathering all the necessary information about the tool—such as the path to the compiler binary, required libraries, and default flags—and packaging it into a ToolchainInfo provider.
The ToolchainInfo provider is a simple Starlark struct that can hold arbitrary key-value pairs. The rule that uses the toolchain will access this provider to get the information it needs. The specific fields expected in the ToolchainInfo struct are part of the contract defined by the toolchain_type.18 This rule does not execute any build actions itself; it merely collects artifacts and forwards them to the consuming rule.18

```
# //bar_tools/toolchain.bzl
def _bar_toolchain_impl(ctx):
    #... logic to locate compiler, linker, etc....
    toolchain_info = ToolchainInfo(
        compiler_path = ctx.file.compiler.path,
        linker_path = ctx.file.linker.path,
    )
    return [toolchain_info]

bar_toolchain = rule(
    implementation = _bar_toolchain_impl,
    attrs = {
        "compiler": attr.label(allow_single_file = True),
        "linker": attr.label(allow_single_file = True),
    },
)
```


toolchain: The Bridge

The generic toolchain rule is the critical component that links the abstract interface (toolchain_type) with a concrete implementation. It is the "binding" in the dependency injection analogy. A target of this rule specifies three crucial pieces of information 11:
toolchain_type: The label of the toolchain_type this toolchain implements.
toolchain: The label of the specific target (e.g., an instance of bar_toolchain) that provides the ToolchainInfo.
exec_compatible_with and target_compatible_with: A list of constraint_values that define the execution and target platforms for which this toolchain is valid.
This is where platform constraints are attached to a specific tool implementation, enabling Bazel's resolution algorithm to make an informed selection.

```
# //bar_tools/BUILD
load(":toolchain.bzl", "bar_toolchain")

# A concrete implementation for Linux x86_64
bar_toolchain(
    name = "linux_x86_64_impl",
    compiler = ":barc-linux",
    linker = ":barl-linux",
)

# The bridge that connects the implementation to the type and adds constraints.
toolchain(
    name = "linux_x86_64_toolchain",
    toolchain_type = "//bar_tools:toolchain_type",
    exec_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
    toolchain = ":linux_x86_64_impl",
)
```


2.2 The Resolution Algorithm Unveiled

With the components defined, Bazel follows a deterministic process to select the correct toolchain for a given build action.

Registration

Before a toolchain can be selected, it must be made available to Bazel. This process is called registration. In the modern Bzlmod paradigm, toolchains are registered in one of two ways:
register_toolchains() in MODULE.bazel: This function takes a list of labels pointing to toolchain targets, making them available for resolution for any target within the workspace.21
--extra_toolchains command-line flag: This flag allows for registering toolchains on a per-invocation basis, which is useful for testing or overriding default toolchains.20
Bazel establishes a clear priority order for registered toolchains. Toolchains specified on the command line have the highest priority, followed by those registered in the root module's MODULE.bazel file, and finally those registered by dependency modules.18 Within a single
register_toolchains call that uses a target pattern (e.g., //...), toolchains in subpackages are registered before those in parent packages, and within a single package, they are registered in lexicographical order of their names.18

Matching

When a rule requiring a toolchain_type is analyzed, Bazel performs the following resolution steps 20:
Identify Inputs: Bazel identifies the required toolchain_type(s) from the rule definition and the curren
t target platform (specified via the --platforms flag).
Filter by Target Compatibility: It collects all registered toolchains that implement the required toolchain_type. It then filters this list, keeping only the toolchains whose target_compatible_with constraints are a subset of the constraints defined on the target platform.
Find a Valid Execution Platform: For each remaining candidate toolchain, Bazel searches for a compatible execution platform. An execution platform is compatible if its constraints satisfy the toolchain's exec_compatible_with constraints.
Select the Highest Priority: If multiple valid pairs of (toolchain, execution platform) are found, Bazel selects the pair whose toolchain was registered with the highest priority (i.e., the one registered first in the priority list). This makes the registration order a crucial factor for breaking ties.23
Once a toolchain is selected, only that specific toolchain target becomes a dependency of the rule being analyzed. The entire space of other candidate toolchains is ignored, keeping the build graph lean.18 The consuming rule can then access the selected tool's implementation via
ctx.toolchains["//bar_tools:toolchain_type"], which returns the ToolchainInfo provider.18

Debugging the Magic

The toolchain resolution process, while powerful, can sometimes be opaque. To diagnose issues where an unexpected toolchain is chosen or no toolchain is found, Bazel provides an indispensable debugging flag: --toolchain_resolution_debug. When used with a regex matching a toolchain type (e.g., --toolchain_resolution_debug=@rules_python//python:toolchain_type), Bazel will print a verbose log of the entire resolution process. This log details which toolchains were considered, which were filtered out at each step, and why, making it possible to precisely understand and correct the configuration.19

Section 3: Practical Implementation: Building a Hermetic Python Toolchain with Bzlmod

This section provides a complete, step-by-step guide for creating a hermetic Python toolchain. The goal is to define a toolchain that downloads a specific, pre-packaged Python distribution, ensuring that the build is entirely self-contained and independent of any Python interpreter installed on the host system. This process follows the modern, idiomatic pattern of using a repository_rule invoked via a module_extension and registered in the MODULE.bazel file.

3.1 Step 1: Fetching the Custom Python Distribution via a repository_rule

The first step is to define the logic for fetching and preparing the custom Python distribution. Since this involves downloading an external artifact and generating BUILD files on the fly, the correct tool is a Starlark repository_rule. This rule will encapsulate all the logic needed to create a new Bazel repository containing the Python interpreter and its associated build definitions.1
This logic should be placed in a .bzl file, for example, tools/py_distribution.bzl.

```
# tools/py_distribution.bzl

def _py_distribution_impl(repository_ctx):
    """Implementation of the py_distribution repository rule."""
    # 1. Download and extract the specified Python distribution archive.
    repository_ctx.download_and_extract(
        url = repository_ctx.attr.url,
        sha256 = repository_ctx.attr.sha256,
        stripPrefix = repository_ctx.attr.strip_prefix,
    )

    # 2. Prepare substitutions for the BUILD file template.
    # This combines the OS and CPU constraints into a format the toolchain rule expects.
    constraints = [
        '"@platforms//os:%s"' % repository_ctx.attr.target_os,
        '"@platforms//cpu:%s"' % repository_ctx.attr.target_cpu,
    ]

    # 3. Generate the BUILD.bazel file inside the new repository from a template.
    # This is the key step that makes the downloaded content usa
```