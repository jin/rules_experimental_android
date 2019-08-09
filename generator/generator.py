#!/usr/bin/python3

import argparse
import subprocess
import re
import os
import sys
from collections import OrderedDict
from functools import reduce

GRADLE_CONFIGURATIONS = [
    "api",
    "implementation",
    "testImplementation",
    "androidTestImplementation",
    "kapt",
    "annotationProcessor",
]

ANNOTATION_PROCESSORS_LIBRARY = {
    "androidx.room:room-compiler": ":androidx_room_room_compiler_library",
    "androidx.databinding:databinding-compiler": ":androidx_databinding_databinding_compiler_library",
    "androidx.lifecycle:lifecycle-compiler": ":androidx_lifecycle_lifecycle_compiler_library",
}

ANNOTATION_PROCESSORS_PLUGIN = {
    "androidx.room:room-compiler": ":androidx_room_room_compiler_plugin",
    "androidx.databinding:databinding-compiler": ":androidx_databinding_databinding_compiler_plugin",
    "androidx.lifecycle:lifecycle-compiler": ":androidx_lifecycle_lifecycle_compiler_plugin",
}

ANNOTATION_PROCESSORS_SNIPPETS = {
    "androidx.room:room-compiler": """
java_plugin(
    name = "androidx_room_room_compiler_plugin",
    processor_class = "androidx.room.RoomProcessor",
    deps = ["@maven//:androidx_room_room_compiler"],
)

java_library(
    name = "androidx_room_room_compiler_library",
    exports = [
        "@maven//:androidx_room_room_compiler",
    ],
    exported_plugins = [
        ":androidx_room_room_compiler_plugin"
    ],
)
""",
    "androidx.databinding:databinding-compiler": """
java_plugin(
    name = "androidx_databinding_databinding_compiler_plugin",
    processor_class = "androidx.databinding.annotationprocessor.ProcessDataBinding",
    deps = ["@maven//:androidx_databinding_databinding_compiler"],
    generates_api = 1,
    visibility = ["//visibility:public"],
)

java_library(
    name = "androidx_databinding_databinding_compiler_library",
    exports = [
        "@maven//:androidx_databinding_databinding_compiler",
    ],
    exported_plugins = [
        ":androidx_databinding_databinding_compiler_plugin",
    ],
)
""",
    "androidx.lifecycle:lifecycle-compiler": """
java_plugin(
    name = "androidx_lifecycle_lifecycle_compiler_plugin",
    processor_class = "androidx.lifecycle.LifecycleProcessor",
    deps = ["@maven//:androidx_lifecycle_lifecycle_compiler"],
)

java_library(
    name = "androidx_lifecycle_lifecycle_compiler_library",
    exports = [
        "@maven//:androidx_lifecycle_lifecycle_compiler",
    ],
    exported_plugins = [
        ":androidx_lifecycle_lifecycle_compiler_plugin",
    ],
)
""",
}

BAZELRC = """
build --android_aapt=aapt2
build --strategy=KotlinCompile=worker
build --strict_java_deps=off
build --experimental_android_databinding_v2
build --android_databinding_use_v3_4_args
"""

RULES_KOTLIN_WORKSPACE = """
RULES_KOTLIN_VERSION = "ecc895796f503f43a2f2fb2a120ee54fa597cd34"
http_archive(
    name = "io_bazel_rules_kotlin",
    strip_prefix = "rules_kotlin-%s" % RULES_KOTLIN_VERSION,
    url = "https://github.com/cgruber/rules_kotlin/archive/%s.tar.gz" % RULES_KOTLIN_VERSION,
    sha256 = "",
)
load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kotlin_repositories", "kt_register_toolchains")

kotlin_repositories()
kt_register_toolchains()
"""

BUILD_TEMPLATE = """
load("@io_bazel_rules_kotlin//kotlin:kotlin.bzl", "kt_android_library")

kt_android_library(
    name = "lib_{app_flavor}",
    srcs = glob([{app_srcs}]),
    manifest = "{app_manifest}",
    custom_package = "{app_custom_package}",
    # enable_data_binding = 1,
    resource_files = glob(["{app_resource_files}/**"]),
    assets = glob(["{app_assets_dir}/**"]),
    assets_dir = "{app_assets_dir}/",
    deps = [
{app_deps}
    ],
    plugins = [
{app_plugins}
    ],
)
android_binary(
    name = "app_{app_flavor}",
    manifest = "{app_manifest}",
    manifest_values = {{
        "minSdkVersion": "14",
    }},
    custom_package = "{app_custom_package}",
    deps = [":lib_{app_flavor}"],
    multidex = "native",
)

{extra_targets}
"""

WORKSPACE_TEMPLATE = """
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_experimental_android",
    url = "https://github.com/jin/rules_experimental_android/archive/master.zip",
    strip_prefix = "rules_experimental_android-master",
)

RULES_JVM_EXTERNAL_TAG = "2.6.1"
RULES_JVM_EXTERNAL_SHA = "45203b89aaf8b266440c6b33f1678f516a85b3e22552364e7ce6f7c0d7bdc772"

http_archive(
    name = "rules_jvm_external",
    strip_prefix = "rules_jvm_external-%s" % RULES_JVM_EXTERNAL_TAG,
    sha256 = RULES_JVM_EXTERNAL_SHA,
    url = "https://github.com/bazelbuild/rules_jvm_external/archive/%s.zip" % RULES_JVM_EXTERNAL_TAG,
)

load("@rules_jvm_external//:specs.bzl", "maven")

load("@rules_jvm_external//:defs.bzl", "maven_install")
maven_install(
    name = "maven",
    artifacts = [
{artifacts}
    ],
    repositories = [
        "https://maven.google.com",
        "https://jcenter.bintray.com",
        "https://repo1.maven.org/maven2",
    ],
    use_unsafe_shared_cache = True,
)

# bind(
#     name = "databinding_annotation_processor",
#     actual = "//:androidx_databinding_databinding_compiler_plugin"
# )
"""

def generate_gradle(modules, configurations, write_to_project_directory):
    directory = os.environ["BUILD_WORKSPACE_DIRECTORY"]
    gradlew = os.path.join(directory, "gradlew")
    artifacts = []
    configuration_to_artifacts = {}
    artifact_regexp = re.compile(r'^.---\s.+:.+:.+')

    cmd = [gradlew, "--console", "plain"]

    for module in modules:
        module_cmd = cmd + ["%s:dependencies" % module]
        if len(configurations) > 0:
            for configuration in configurations:
                configured_cmd = module_cmd + ["--configuration", configuration]
                artifacts.append("# " + module + ":" + configuration)
                try:
                    raw_gradle_output = subprocess.check_output(configured_cmd, encoding="utf-8", cwd=directory)
                except subprocess.CalledProcessError as e:
                    print("Execution of \"gradlew dependencies\" failed: ", e)
                    sys.exit(1)
                configuration_artifacts = (
                    list(
                        map(lambda line: line.split()[1],
                            filter(lambda line: artifact_regexp.search(line),
                                   raw_gradle_output.splitlines())))
                    )
                configuration_to_artifacts[configuration] = configuration_artifacts
                artifacts.extend(configuration_artifacts)

    # if len(modules) > 0:
    #     for module in modules:
    #         module_cmd = cmd + ["%s:dependencies" % module]
    #         if len(configurations) > 0:
    #             for configuration in configurations:
    #                 configured_cmd = module_cmd + ["--configuration", configuration]
    #                 artifacts.append("# " + module + ":" + configuration)
    #                 try:
    #                     raw_gradle_output = subprocess.check_output(configured_cmd, encoding="utf-8", cwd=directory)
    #                 except subprocess.CalledProcessError as e:
    #                     print("Execution of \"gradlew dependencies\" failed: ", e)
    #                     sys.exit(1)
    #                 configuration_artifacts = map(lambda line: line.split()[1],
    #                                               filter(lambda line: artifact_regexp.search(line),
    #                                                      raw_gradle_output.splitlines()))
    #                 configuration_to_artifacts[configuration] = configuration_artifacts
    #                 artifacts.extend(configuration_artifacts)
    #         else:
    #             artifacts.append("# " + module)
    #             artifacts.extend(
    #                 map(
    #                     lambda line: line.split()[1],
    #                     filter(
    #                         lambda line: artifact_regexp.search(line),
    #                         subprocess.check_output(cmd, encoding="utf-8", cwd=directory).splitlines())
    #                 )
    #             )
    #             # Dedupe the list
    #             artifacts = OrderedDict((x, True) for x in artifacts).keys()
    # else:
    #     configured_cmd = cmd + ["dependencies"]
    #     artifacts.extend(
    #         map(
    #             lambda line: line.split()[1],
    #             filter(
    #                 lambda line: artifact_regexp.search(line),
    #                 subprocess.check_output(configured_cmd, encoding="utf-8", cwd=directory).splitlines())
    #         )
    #     )
    #     # Dedupe the list
    #     artifacts = OrderedDict((x, True) for x in artifacts).keys()

    WORKSPACE = WORKSPACE_TEMPLATE.format(
        artifacts = "\n".join(map(lambda a: "        " + a if a.startswith("#") else "        \"%s\"," % a, artifacts))
    )

    android_plugin_enabled = True if "android" in subprocess.check_output([gradlew, "properties"], encoding="utf-8", cwd=directory) else False

    if android_plugin_enabled:
        WORKSPACE = WORKSPACE + "\nandroid_sdk_repository(name = \"androidsdk\")"
        WORKSPACE = WORKSPACE + RULES_KOTLIN_WORKSPACE
        source_sets = subprocess.check_output([gradlew, "sourceSets", "--console", "plain"], encoding="utf-8", cwd=directory)
        source_sets = map(lambda source_set: source_set.split("\n"), source_sets.split("\n\n"))
        source_sets = filter(lambda source_set: source_set[0] in ["androidTest", "test", "main", "prod", "mock"], source_sets)
        source_sets_map = {}
        for source_set in source_sets:
            paths = {}
            for entry in source_set[2:]:
                key, val = entry.split(":")
                if key == "Java sources":
                    paths["srcs"] = val[2:-1]
                elif key == "Manifest file":
                    paths["manifest"] = val.strip()
                elif key == "Assets":
                    paths["assets_dir"] = val[2:-1]
                elif key == "Android resources":
                    paths["resource_files"] = val[2:-1]

            if source_set[0] == "androidTest":
                source_sets_map["test_android_binary"] = paths
            elif source_set[0] == "main":
                source_sets_map["android_binary"] = paths
            elif source_set[0] == "test":
                source_sets_map["android_local_test"] = paths
            elif source_set[0] == "prod":
                source_sets_map["prod"] = paths
            elif source_set[0] == "mock":
                source_sets_map["mock"] = paths


        # Open the file as f.
        # The function readlines() reads the file.
        package_regexp = re.compile(r'package=".+"')
        with open(os.path.join(directory, source_sets_map["android_binary"]["manifest"])) as f:
            content = f.read().splitlines()
        for line in content:
            if (package_regexp.search(line)):
                package = line.split('"')[1]

        def generate_targets_for_artifacts(artifacts):
            return list(map(lambda a: "        \"@maven//:%s\"," % "_".join(a.split(":")[:2]).replace(".", "_").replace("-", "_").replace(":", "_"), artifacts))

        annotation_processor_library_deps = [
            ANNOTATION_PROCESSORS_LIBRARY[coordinates]
            for coordinates in map(lambda c: ":".join(c.split(":")[0:2]), configuration_to_artifacts["annotationProcessor"])]
        annotation_processor_plugin_deps = [
            ANNOTATION_PROCESSORS_PLUGIN[coordinates]
            for coordinates in map(lambda c: ":".join(c.split(":")[0:2]), configuration_to_artifacts["annotationProcessor"])]
        annotation_processor_extra_targets = [
            ANNOTATION_PROCESSORS_SNIPPETS[coordinates]
            for coordinates in map(lambda c: ":".join(c.split(":")[0:2]), configuration_to_artifacts["annotationProcessor"])]

        app_flavor = "prod"
        BUILD = BUILD_TEMPLATE.format(
            app_flavor = app_flavor,
            app_manifest = source_sets_map["android_binary"]["manifest"],
            # app_srcs = ",".join(["\"%s/**\"" % srcs_path for srcs_path in [source_sets_map["android_binary"]["srcs"], source_sets_map[app_flavor]["srcs"]]]),
            app_srcs = ",".join(["\"%s/**\"" % srcs_path for srcs_path in [source_sets_map["android_binary"]["srcs"]]]),
            app_resource_files = source_sets_map["android_binary"]["resource_files"],
            app_assets_dir = source_sets_map["android_binary"]["assets_dir"],
            app_custom_package = package,
            app_deps = "\n".join(
                generate_targets_for_artifacts(configuration_to_artifacts["implementation"]) +
                generate_targets_for_artifacts(configuration_to_artifacts["api"]) +
                list(map(lambda x: "        \"%s\"," % x, annotation_processor_library_deps))
            ),
            app_plugins = "\n".join(map(lambda x: "        \"%s\"," % x, annotation_processor_plugin_deps)),
            extra_targets = "\n".join(annotation_processor_extra_targets),
        )


        if write_to_project_directory:
            os.chdir(directory)
            f = open("BUILD.bazel", "w")
            f.write(BUILD)
            f.close()

            f = open("WORKSPACE", "w")
            f.write(WORKSPACE)
            f.close()

            f = open(".bazelrc", "w")
            f.write(BAZELRC)
            f.close()
        else:
            print(WORKSPACE)
            print(BUILD)
    else:
        raise RuntimeError("Project generation is only supported for Android projects.")


def main():
    parser = argparse.ArgumentParser(description="Generate a maven_install declaration from Gradle projects")
    subparsers = parser.add_subparsers(dest="build_system", help="Select a build system")

    gradle_parser = subparsers.add_parser("gradle", help="Generate for the Gradle build system.")
    gradle_parser.add_argument(
        "-m",
        "--module",
        help="The selected module(s) to resolve dependencies for. Defaults to the root module. Can be specified multiple times.",
        action="append",
        type=str,
        default = [],
        required = True,
    )
    gradle_parser.add_argument(
        "-c",
        "--configuration",
        help="The configuration of dependencies to resolve. Defaults to all configurations. Can be specified multiple times.",
        action="append",
        type=str,
        choices = GRADLE_CONFIGURATIONS,
        default = [],
        required = True,
    )
    gradle_parser.add_argument(
        "-w",
        "--write_to_project_directory",
        action='store_true',
        default = False,
    )
    args = parser.parse_args()
    if args.build_system == "gradle":
        generate_gradle(args.module, args.configuration, args.write_to_project_directory)
    else:
        parser.print_usage()

main()
