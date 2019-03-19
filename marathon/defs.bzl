def _marathon_android_test_impl(ctx):
    instr_info = ctx.attr.test_app[AndroidInstrumentationInfo]
    app = instr_info.target_apk
    test_app = instr_info.instrumentation_apk
    marathonfile = ctx.actions.declare_file("Marathonfile")

    runfiles = ctx.runfiles(
        files = [
            ctx.file._marathon,
            app,
            test_app,
            marathonfile,
            ctx.file._adb,
        ] + ctx.files._androidsdk_files,
    )

    adb_path = ctx.expand_location("$(location @androidsdk//:adb)", [ctx.attr._adb])
    sdk_path = adb_path.split("adb")[0] + ".."

    ctx.actions.expand_template(
        template = ctx.file._marathonfile_template,
        output = marathonfile,
        substitutions = {
            "{name}": ctx.label.name,
            "{applicationApk}": app.short_path,
            "{testApplicationApk}": test_app.short_path,
            "{outputDir}": "/tmp",
            "{androidSdk}": sdk_path,
        },
    )

    test_cmd = [
        ctx.file._marathon.short_path, "--marathonfile", marathonfile.short_path,
    ]

    test_runner = ctx.actions.declare_file("test_runner.sh")
    ctx.actions.write(test_runner, " ".join(test_cmd), True)

    return [
        DefaultInfo(
            executable = test_runner,
            runfiles = runfiles,
        )
    ]

marathon_android_test = rule(
    implementation = _marathon_android_test_impl,
    attrs = {
        "test_app": attr.label(
            providers = [AndroidInstrumentationInfo]
        ),
        "_adb": attr.label(
            default = "@androidsdk//:adb",
            allow_single_file = True,
        ),
        "_androidsdk_files": attr.label(
            default = "@androidsdk//:files",
            allow_files = True,
        ),
        "_marathon": attr.label(
            default = "//third_party/marathon-0.4.0:bin/marathon",
            allow_single_file = True,
            executable = True,
            cfg = "host",
        ),
        "_marathonfile_template": attr.label(
            default = "//marathon:Marathonfile.tpl",
            allow_single_file = True,
            cfg = "host",
        ),
    },
    test = True,
)
