@echo off
setlocal
for %%S in (runtime_word_suite runtime_number_suite runtime_meta_suite runtime_shell_suite) do (
  call "%~dp0..\..\tools\run_godot.cmd" --headless --path "%~dp0.." res://tests/%%S.tscn
  if errorlevel 1 exit /b 1
)
