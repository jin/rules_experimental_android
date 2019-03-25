AVDMANAGER_DEVICE_TYPE_ID_MAP = {
    "nexus_10": 6,
    "nexus_4": 7,
    "nexus_5": 8,
    "pixel": 17,
    "pixel_c": 18,
    "pixel_xl": 19,
    "generic_4_7": 30,
    "generic_5_1": 31,
    "generic_7": 33,
}

MAC_STUB_SCRIPT = """#!/bin/bash

set -euo pipefail

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -d|--enable_display)
      ENABLE_DISPLAY=1
      shift
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported test flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

export ANDROID_AVD_HOME=$TEST_TMPDIR/avd_home
mkdir -p $ANDROID_AVD_HOME

export ANDROID_SDK_ROOT=$TEST_SRCDIR/{sdk_path}
export ANDROID_HOME=$ANDROID_SDK_ROOT # required by Composer
export DYLD_LIBRARY_PATH=$ANDROID_SDK_ROOT/tools/lib64:$ANDROID_SDK_ROOT/tools/lib64/qt/lib

$ANDROID_SDK_ROOT/tools/bin/avdmanager \
    create avd  \
    -n {test_target_label} \
    -k "system-images;android-{api_level};{api_type};x86" \
    -d {device_type}

port_num=$(netstat -aln | awk '
  $6 == "LISTEN" {{
    if ($4 ~ "[.:][0-9]+$") {{
      split($4, a, /[:.]/);
      port = a[length(a)];
      p[port] = 1
    }}
  }}
  END {{
    srand({awk_srand_seed})
    for (i = int(rand() * 1000 + 5000); i < 6000 && p[i]; i++){{}};
    if (i == 6000) {{exit 1}};
    print i
  }}
')

NO_WINDOW=""
if [ -z ${{ENABLE_DISPLAY+0}} ];
then
    NO_WINDOW="-no-window"
fi

nohup $ANDROID_SDK_ROOT/tools/emulator \
    @{test_target_label} \
    -wipe-data \
    -no-audio \
    $NO_WINDOW \
    -memory 1024 \
    -accel on \
    -engine qemu2 \
    -gpu host \
    -no-boot-anim \
    -port $port_num \
    -no-snapshot-save &

attempts=0
max_attempts=100
while [ "$($ANDROID_SDK_ROOT/platform-tools/adb -s emulator-$port_num shell getprop sys.boot_completed | tr -d '\r' )" != "1" ] ;
do
    sleep 3
    echo "Trying to connect to emulator-$port_num: attempt $attempts/$max_attempts"
    if [ $attempts -eq $max_attempts ];
    then
        echo "Unable to connect to emulator-$port_num"
        exit 1
    fi
    (( attempts += 1 ))
done

# export XML_OUTPUT_FILE=$TEST_UNDECLARED_OUTPUTS_DIR/junit4-reports/emulator-$port_num.xml

java -jar {composer_short_path} \
    --apk {apk_short_path} \
    --test-apk {test_apk_short_path} \
    --devices emulator-$port_num \
    --output-directory $TEST_UNDECLARED_OUTPUTS_DIR \
    --shard false \
    --verbose-output true \
    --keep-output-on-exit

# TODO: --with-orchestrator, --extra-apks
"""

def _get_system_image_filegroup(api_level, google_apis):
    api_type = "google" if google_apis else "default"
    return Label("@androidsdk//:emulator_images_%s_%s_x86" % (api_type, api_level))

def _get_qemu2_extra(api_level, google_apis):
    api_type = "google" if google_apis else "default"
    return Label("@androidsdk//:emulator_images_%s_%s_x86_qemu2_extra" % (api_type, api_level))

def _composer_instrumentation_test_impl(ctx):
    instr_info = ctx.attr.test_apk[AndroidInstrumentationInfo]
    apk = instr_info.target_apk
    test_apk = instr_info.instrumentation_apk

    runfiles = ctx.runfiles(
        files = [
                    apk,
                    ctx.file._adb,
                    ctx.file._avdmanager,
                    ctx.file._composer,
                    ctx.file._emulator,
                    test_apk,
                ] + ctx.files._androidsdk_files +
                ctx.files._system_image_filegroup +
                ctx.files._qemu2_x86 +
                ctx.files._qemu2_extra,
    )

    test_script = MAC_STUB_SCRIPT.format(
        api_level = ctx.attr.api_level,
        api_type = "google_apis" if (ctx.attr.google_apis) else "default",
        apk_short_path = apk.short_path,
        awk_srand_seed = hash(ctx.label.package + ctx.label.name),
        composer_short_path = ctx.file._composer.short_path,
        device_type = AVDMANAGER_DEVICE_TYPE_ID_MAP.get(ctx.attr.device_type),
        sdk_path = ctx.expand_location("$(location @androidsdk//:sdk_path)", [ctx.attr._sdk_path]).replace("external/", ""),
        test_apk_short_path = test_apk.short_path,
        test_target_label = "Bazel_" + str(hash(ctx.label.package + ctx.label.name)),
    )

    test_runner = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.write(
        test_runner,
        test_script,
        True,  # executable
    )

    return [
        DefaultInfo(
            executable = test_runner,
            runfiles = runfiles,
        ),
    ]

composer_instrumentation_test = rule(
    implementation = _composer_instrumentation_test_impl,
    attrs = {
        "api_level": attr.int(mandatory = True),
        "device_type": attr.string(values = AVDMANAGER_DEVICE_TYPE_ID_MAP.keys(), default = "generic_4_7"),
        "extra_apks": attr.label_list(default = [], allow_files = True),
        "google_apis": attr.bool(default = False),
        "test_apk": attr.label(providers = [AndroidInstrumentationInfo]),
        "_adb": attr.label(default = "@androidsdk//:adb", allow_single_file = True),
        "_androidsdk_files": attr.label(default = "@androidsdk//:files", allow_files = True),
        "_avdmanager": attr.label(default = "@androidsdk//:tools/bin/avdmanager", allow_single_file = True),
        "_composer": attr.label(default = "//third_party/composer:composer-0.6.0.jar", allow_single_file = True),
        "_emulator": attr.label(default = "@androidsdk//:tools/emulator", allow_single_file = True),
        "_qemu2_extra": attr.label(default = _get_qemu2_extra, allow_files = True),
        "_qemu2_x86": attr.label(default = "@androidsdk//:qemu2_x86", allow_files = True),
        "_sdk_path": attr.label(default = "@androidsdk//:sdk_path"),
        "_system_image_filegroup": attr.label(default = _get_system_image_filegroup, allow_files = True),
    },
    test = True,
)
