workspace(name = "rules_experimental_android")

android_sdk_repository(name = "androidsdk")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

RULES_JVM_EXTERNAL_TAG = "1.1"
RULES_JVM_EXTERNAL_SHA = "ade316ec98ba0769bb1189b345d9877de99dd1b1e82f5a649d6ccbcb8da51c1f"

http_archive(
    name = "rules_jvm_external",
    strip_prefix = "rules_jvm_external-%s" % RULES_JVM_EXTERNAL_TAG,
    sha256 = RULES_JVM_EXTERNAL_SHA,
    url = "https://github.com/bazelbuild/rules_jvm_external/archive/%s.zip" % RULES_JVM_EXTERNAL_TAG,
)

load("@rules_jvm_external//:defs.bzl", "maven_install")

maven_install(
    artifacts = [
        "androidx.annotation:annotation:1.0.2",
        "androidx.test.espresso:espresso-core:3.1.1",
        "androidx.test.espresso:espresso-intents:3.1.1",
        "androidx.test.ext:junit:1.1.1-alpha02",
        "androidx.test:core:1.1.0",
        "androidx.test:runner:1.1.1",
        "androidx.test:monitor:1.1.1",
        "com.google.guava:guava:27.1-android",
        "junit:junit:4.12",
        "org.hamcrest:java-hamcrest:2.0.0.0",
    ],
    repositories = [
        "https://maven.google.com",
        "https://repo1.maven.org/maven2",
    ],
    use_unsafe_shared_cache = True,
)

# Android Test Support
#
# This repository contains the supporting tools to run Android instrumentation tests,
# like the emulator definitions (android_device) and the device broker/test runner.
ATS_TAG = "83a200e741729882b9a97c7af7684d6726e9dfde"
ATS_SHA256 = "c8cb2eee3360c9822f567fb5ce3c5c3531f91f185a10d181957ebd28c23554b8"

http_archive(
    name = "android_test_support",
    sha256 = ATS_SHA256,
    strip_prefix = "android-test-%s" % ATS_TAG,
    urls = ["https://github.com/android/android-test/archive/%s.tar.gz" % ATS_TAG],
)

load("@android_test_support//:repo.bzl", "android_test_repositories")
android_test_repositories()
