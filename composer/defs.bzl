def _composer_instrumentation_test_impl(ctx):
    instr_info = ctx.attr.test_app[AndroidInstrumentationInfo]
    app = instr_info.target_apk
    test_app = instr_info.instrumentation_apk

    runfiles = ctx.runfiles(
        files = [
            ctx.file._composer,
            app,
            test_app,
        ]
    )

    test_cmd = [
        "java", "-jar", ctx.file._composer.short_path,
        "--apk", app.short_path,
        "--test-apk", test_app.short_path,
    ]

    test_runner = ctx.actions.declare_file("test_runner.sh")
    ctx.actions.write(test_runner, " ".join(test_cmd), True)

    return [
        DefaultInfo(
            executable = test_runner,
            runfiles = runfiles,
        )
    ]

composer_instrumentation_test = rule(
    implementation = _composer_instrumentation_test_impl,
    attrs = {
        "test_app": attr.label(
            providers = [AndroidInstrumentationInfo]
        ),
        "_composer": attr.label(
            default = "//third_party/composer:composer-0.6.0.jar",
            allow_single_file = True
        ),
    },
    test = True,
)
