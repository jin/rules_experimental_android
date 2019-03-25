# Experimental Bazel Android

This repository contains experimental rules and tools for building and testing
Android projects with Bazel.

Please do not depend on these for production usage.

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

- Two `android_binary` targets, one for the test and one for the app under test.
  The test `android_binary` must reference the `android_binary` under test via
  the `instruments` attribute.
- Emulator system images of your desired API levels. Download through
  `sdkmanager`.

In your BUILD file, declare the `composer_instrumentation_test` target:

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
    device_type = "pixel",  # pixel, pixel_c, nexus_4, generic_4_7, etc.
    api_level = 28,  # Ensure that you have the required system image downloaded into your SDK
    google_apis = True,
)
```

Run:

```
$ bazel test //ui/espresso/BasicSample:BasicSampleComposerTest
```

This instructs Bazel to launch a fresh emulator in sandboxed mode, and utilize
Composer to run the tests on the specified device variant. There is no need to
launch emulators separately.

Bazel will run all these tests in headless emulators (no GUI). Pass the flag
`--test_arg=--enable_display` to enable the GUI.

You can also create a matrix of API levels and device variants using list
comprehension:

```python
DEVICE_TYPES = ["pixel", "pixel_c", "nexus_4", "nexus_10"]
API_LEVELS = [25, 26, 28]

[
    [
        composer_instrumentation_test(
            name = "BasicSampleComposerTest_%s_%s" % (DEVICE_TYPE, API_LEVEL),
            test_apk = ":BasicSampleTest",
            api_level = API_LEVEL,
            device_type = DEVICE_TYPE,
            google_apis = True,
        ) for DEVICE_TYPE in DEVICE_TYPES
    ]
    for API_LEVEL in API_LEVELS
]
```

This generates the following targets:

```
//examples/BasicSample:BasicSampleComposerTest_pixel_c_28
//examples/BasicSample:BasicSampleComposerTest_pixel_c_26
//examples/BasicSample:BasicSampleComposerTest_pixel_c_25
//examples/BasicSample:BasicSampleComposerTest_pixel_28
//examples/BasicSample:BasicSampleComposerTest_pixel_26
//examples/BasicSample:BasicSampleComposerTest_pixel_25
//examples/BasicSample:BasicSampleComposerTest_nexus_4_28
//examples/BasicSample:BasicSampleComposerTest_nexus_4_26
//examples/BasicSample:BasicSampleComposerTest_nexus_4_25
//examples/BasicSample:BasicSampleComposerTest_nexus_10_28
//examples/BasicSample:BasicSampleComposerTest_nexus_10_26
//examples/BasicSample:BasicSampleComposerTest_nexus_10_25
```
  
Tips:

* `composer_integration_test` produces useful test outputs after each run, like
  a HTML report, logcat logs, a Junit4 compatible XML result file, and
  screenshots. You can find these files in `bazel-testlogs` in your project's
  root directory, in an archive called `outputs.zip` if the tests passed, or as
  individual files if they failed.
* Enable GUI display for emulators: `--test_arg=--enable_display` or `--test_arg=-d`
* Limit the number of test jobs: `--local_test_jobs=<int>`
* Show test output during execution: `--test_output=streamed`
* Show errors from test failures: `--test_output=errors`
* Disable sandboxing: `--spawn_strategy=local`
  
### Running with a locally connected device

You can also run the tests on a separately launched emulator or an USB connected
device via USB by specifying `device_type = "local"`. Note that Bazel does not
keep track of the emulator's state, which may lead into correctness issues.

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
    device_type = "local",
)
```

Run:

```
$ bazel test //ui/espresso/BasicSample:BasicSampleComposerTest --test_strategy=exclusive
```

The `--test_strategy=exclusive` flag forces Bazel to run multiple tests
sequentially on the shared device.

### TODO

- [ ] Android Test Orchestrator support
- [ ] Extra APKs support
- [ ] Support testing with multiple locally connected devices
