# Experimental Bazel Android

This repository contains experimental rules and tools for build Android projects
with Bazel.

Please do not depend on these for production usage.

These rules depend on the latest version of Bazel. The version is managed
using `.bazelversion` through
[bazelisk](https://github.com/bazelbuild/bazelisk).

## Usage

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

RULES_EXPERIMENTAL_ANDROID_COMMIT = "" # select a commit here

http_archive(
    name = "rules_experimental_android",
    url = "https://github.com/jin/rules_experimental_android/archive/%s.zip" % RULES_EXPERIMENTAL_ANDROID_COMMIT,
    strip_prefix = "rules_experimental_android-%s" % RULES_EXPERIMENTAL_ANDROID_COMMIT,
)
```

## Composer integration

Integration with the [Composer instrumentation test
runner](https://github.com/gojuno/composer)

Only tested on macOS.

Prerequisites:

- A running Android emulator.
- Two `android_binary` targets, one for the test and one for the app under test.
  The test `android_binary` must reference the `android_binary` under test via
  the `instruments` attribute.

BUILD file:

```python
load("@rules_experimental_android//:defs.bzl", "composer_instrumentation_test")

android_binary(
    name = "BasicSample",
    # ...
)

android_binary(
    name = "BasicSampleTest",
    instruments = ":BasicSample",
    # ...
)

composer_instrumentation_test(
    name = "BasicSampleComposerTest",
    test_app = ":BasicSampleTest",
)
```

Run:

```
$ bazel test //ui/espresso/BasicSample:BasicSampleComposerTest --action_env=ANDROID_HOME
```

If you're running more than one test in a single command, you must use
`--test_strategy=exclusive`.
