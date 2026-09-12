# Regression checks

Run `bash tests/run.sh` with Godot 4.7.2, Bash, rsync, and ripgrep available.
The runner copies the project into a temporary directory, imports it without
existing caches, and runs runtime scripts and editor test scenes separately.
It requires successful exit status, clean error output, and a test completion
marker. The original project's editor settings and input map are not changed.
The temporary project and logs are retained for diagnosis.

Editor checks are ordinary `@tool` scenes and run only with the explicit
`--proto-shape-tests` user argument. Opening those scenes normally does not
start a test or close the editor. Avoid running editor objects from a custom
`--editor --script` SceneTree: that bypasses normal editor cleanup.

These checks supplement the manual editing, gameplay, and exported-runtime
checks in [the release checklist](../release/CHECKLIST.md).
