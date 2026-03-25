## Makefile Review

- **`.PHONY` declarations**: All non-file targets (e.g., `build`, `test`, `clean`) must be declared `.PHONY`. Missing declarations cause incorrect skipping when a file with the same name exists.
- **Tabs for recipes**: Recipe lines must use tabs, not spaces. Flag spaces in recipe indentation.
- **`$(MAKE)` for recursive calls**: Flag `make` in recipes. Use `$(MAKE)` to inherit flags and jobserver.
- **Variable consistency**: Pick `$(VAR)` or `${VAR}` and use it consistently. `$(VAR)` is more conventional in Makefiles.
- **Target dependencies**: Verify targets list all inputs they depend on. Missing dependencies cause stale builds.
- **`:=` vs `=` assignment**: Use `:=` (simply expanded) for performance-sensitive variables. Flag `=` (recursively expanded) when the value is expensive and referenced multiple times.
- **Silent recipes**: Prefer `@` prefix or `.SILENT` for noisy commands only. Don't silence everything as it makes debugging harder.
- **Multi-line readability**: Flag overly long one-liner shell commands in recipes. Use `\` continuation for readability.
