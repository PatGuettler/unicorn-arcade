# Unicorn Arcade workspace notes

- Use the project-local Godot 4.7.1 console at `.tools/godot-4.7.1/Godot_v4.7.1-stable_win64_console.exe` (also stored in the user-level `GODOT_BIN` environment variable).
- Run Godot through `tools/run_godot.cmd`. The wrapper keeps engine logs under the git-ignored `.tools/godot-logs/` directory on `E:` and avoids sandbox approval prompts caused by writes to Windows AppData.
- Keep `.tools/` untracked; it contains the local engine binary, logs, and disposable test tooling.
