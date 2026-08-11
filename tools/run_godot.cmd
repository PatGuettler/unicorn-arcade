@echo off
setlocal
set "PROJECT_ROOT=%~dp0.."
rem The console companion cannot be launched from this project's spaced path
rem on the recovered host (CreateProcess error 193). The paired GUI binary
rem supports --headless and is the same project-local Godot 4.7.1 build.
set "GODOT_EXE=%PROJECT_ROOT%\.tools\godot-4.7.1\Godot_v4.7.1-stable_win64.exe"
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
