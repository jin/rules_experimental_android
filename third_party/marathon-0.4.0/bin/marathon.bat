@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  marathon startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%..

@rem Add default JVM options here. You can also use JAVA_OPTS and MARATHON_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS="-Dkotlinx.coroutines.debug=on"

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if "%ERRORLEVEL%" == "0" goto init

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe

if exist "%JAVA_EXE%" goto init

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:init
@rem Get command-line arguments, handling Windows variants

if not "%OS%" == "Windows_NT" goto win9xME_args

:win9xME_args
@rem Slurp the command line arguments.
set CMD_LINE_ARGS=
set _SKIP=2

:win9xME_args_slurp
if "x%~1" == "x" goto execute

set CMD_LINE_ARGS=%*

:execute
@rem Setup the command line

set CLASSPATH=%APP_HOME%\lib\cli-0.4.0.jar;%APP_HOME%\lib\vendor-ios-0.4.0.jar;%APP_HOME%\lib\vendor-android-0.4.0.jar;%APP_HOME%\lib\core-0.4.0.jar;%APP_HOME%\lib\usage-0.4.0.jar;%APP_HOME%\lib\html-report-0.4.0.jar;%APP_HOME%\lib\execution-timeline-0.4.0.jar;%APP_HOME%\lib\ddmlib-26.3.0.jar;%APP_HOME%\lib\common-26.3.0.jar;%APP_HOME%\lib\kotlin-stdlib-jdk8-1.3.20.jar;%APP_HOME%\lib\kotlinx-coroutines-core-1.1.1.jar;%APP_HOME%\lib\kotlin-logging-1.4.9.jar;%APP_HOME%\lib\jackson-module-kotlin-2.9.4.1.jar;%APP_HOME%\lib\kotlin-reflect-1.3.20.jar;%APP_HOME%\lib\slf4k-api-1.0.0.jar;%APP_HOME%\lib\logback-classic-1.2.3.jar;%APP_HOME%\lib\kotlin-argparser-2.0.7.jar;%APP_HOME%\lib\jackson-datatype-jsr310-2.9.6.jar;%APP_HOME%\lib\allure-environment-writer-1.0.0.jar;%APP_HOME%\lib\allure-testng-2.8.1.jar;%APP_HOME%\lib\allure-descriptions-javadoc-2.8.1.jar;%APP_HOME%\lib\allure-java-commons-2.8.1.jar;%APP_HOME%\lib\allure-model-2.8.1.jar;%APP_HOME%\lib\jackson-databind-2.9.7.jar;%APP_HOME%\lib\jackson-annotations-2.9.5.jar;%APP_HOME%\lib\jackson-dataformat-yaml-2.9.6.jar;%APP_HOME%\lib\gson-2.8.5.jar;%APP_HOME%\lib\commons-text-1.3.jar;%APP_HOME%\lib\rsync4j-all-3.1.2-12.jar;%APP_HOME%\lib\rsync4j-windows-x86-3.1.2-12.jar;%APP_HOME%\lib\rsync4j-windows-x86_64-3.1.2-12.jar;%APP_HOME%\lib\rsync4j-core-3.1.2-12.jar;%APP_HOME%\lib\commons-io-2.6.jar;%APP_HOME%\lib\influxdb-java-2.13.jar;%APP_HOME%\lib\dd-plist-1.21.jar;%APP_HOME%\lib\axmlparser-1.0.jar;%APP_HOME%\lib\guava-27.0-jre.jar;%APP_HOME%\lib\sshj-0.26.0.jar;%APP_HOME%\lib\jansi-1.17.1.jar;%APP_HOME%\lib\parser-2.0.1.jar;%APP_HOME%\lib\imgscalr-lib-4.2.jar;%APP_HOME%\lib\google-analytics-java-2.0.0.jar;%APP_HOME%\lib\kotlin-stdlib-jdk7-1.3.20.jar;%APP_HOME%\lib\xenocom-0.0.7.jar;%APP_HOME%\lib\kotlin-stdlib-1.3.20.jar;%APP_HOME%\lib\kotlinx-coroutines-core-common-1.1.1.jar;%APP_HOME%\lib\jcl-over-slf4j-1.7.25.jar;%APP_HOME%\lib\slf4j-api-1.7.25.jar;%APP_HOME%\lib\kotlin-runtime-1.0.2.jar;%APP_HOME%\lib\logback-core-1.2.3.jar;%APP_HOME%\lib\jackson-core-2.9.7.jar;%APP_HOME%\lib\snakeyaml-1.18.jar;%APP_HOME%\lib\tika-core-1.19.1.jar;%APP_HOME%\lib\aspectjrt-1.9.1.jar;%APP_HOME%\lib\joor-java-8-0.9.9.jar;%APP_HOME%\lib\testng-6.14.3.jar;%APP_HOME%\lib\commons-lang3-3.7.jar;%APP_HOME%\lib\converter-moshi-2.4.0.jar;%APP_HOME%\lib\retrofit-2.4.0.jar;%APP_HOME%\lib\msgpack-core-0.8.16.jar;%APP_HOME%\lib\logging-interceptor-3.11.0.jar;%APP_HOME%\lib\okhttp-3.11.0.jar;%APP_HOME%\lib\bcpkix-jdk15on-1.60.jar;%APP_HOME%\lib\bcprov-jdk15on-1.60.jar;%APP_HOME%\lib\jzlib-1.1.3.jar;%APP_HOME%\lib\eddsa-0.2.0.jar;%APP_HOME%\lib\kxml2-2.3.0.jar;%APP_HOME%\lib\httpclient-4.5.3.jar;%APP_HOME%\lib\kotlin-stdlib-common-1.3.20.jar;%APP_HOME%\lib\annotations-13.0.jar;%APP_HOME%\lib\failureaccess-1.0.jar;%APP_HOME%\lib\listenablefuture-9999.0-empty-to-avoid-conflict-with-guava.jar;%APP_HOME%\lib\jsr305-3.0.2.jar;%APP_HOME%\lib\checker-qual-2.5.2.jar;%APP_HOME%\lib\error_prone_annotations-2.2.0.jar;%APP_HOME%\lib\j2objc-annotations-1.1.jar;%APP_HOME%\lib\animal-sniffer-annotations-1.17.jar;%APP_HOME%\lib\jcommander-1.72.jar;%APP_HOME%\lib\bsh-2.0b6.jar;%APP_HOME%\lib\moshi-1.5.0.jar;%APP_HOME%\lib\okio-1.14.0.jar;%APP_HOME%\lib\commons-lang-2.6.jar;%APP_HOME%\lib\argparse4j-0.6.0.jar;%APP_HOME%\lib\processoutput4j-0.0.7.jar;%APP_HOME%\lib\annotations-26.3.0.jar;%APP_HOME%\lib\httpcore-4.4.6.jar;%APP_HOME%\lib\commons-codec-1.9.jar

@rem Execute marathon
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %MARATHON_OPTS%  -classpath "%CLASSPATH%" com.malinskiy.marathon.cli.ApplicationViewKt %CMD_LINE_ARGS%

:end
@rem End local scope for the variables with windows NT shell
if "%ERRORLEVEL%"=="0" goto mainEnd

:fail
rem Set variable MARATHON_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code!
if  not "" == "%MARATHON_EXIT_CONSOLE%" exit 1
exit /b 1

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
