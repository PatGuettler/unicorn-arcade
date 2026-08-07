@echo off
setlocal
set "PROJECT_ROOT=%~dp0.."
set "GODOT_EXE=%PROJECT_ROOT%\.tools\godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe"
set "LOG_DIR=%PROJECT_ROOT%\.tools\godot-logs"
set "GRADLE_USER_HOME=E:\Cache\unicorn-gradle"
set "ANDROID_USER_HOME=%PROJECT_ROOT%\.tools\android-user"

if not exist "%GODOT_EXE%" (
  echo Project-local Godot is missing: "%GODOT_EXE%" 1>&2
  exit /b 1
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
"%GODOT_EXE%" --log-file "%LOG_DIR%\godot-local.log" %*
exit /b %ERRORLEVEL%
