## Bash/Shell Review

- **`set -euo pipefail`**: Must be present near the top of every script. `-e` exits on error, `-u` catches unset variables, `-o pipefail` catches pipe failures.
- **Quote all variables**: Flag unquoted `$var`. Always use `"$var"` to prevent word splitting and globbing. This applies to command substitution too: `"$(cmd)"`.
- **Use `[[ ]]` over `[ ]`**: `[[ ]]` is safer (no word splitting, supports `&&`, `||`, regex). Flag `[ ]` in bash scripts.
- **Don't parse `ls` output**: Flag `for f in $(ls ...)`. Use globbing (`for f in *.txt`) or `find` with `-print0`/`xargs -0`.
- **Avoid `eval`**: Flag `eval` usage. It's almost always a security risk or a sign of a better approach.
- **Heredoc quoting**: Use `<<'EOF'` (quoted) to prevent variable expansion in heredocs that contain literal `$` characters.
- **Exit codes**: Check command exit codes. Flag commands whose failure is silently ignored when it matters.
- **Portable vs bashisms**: If the shebang is `#!/bin/sh`, flag bash-specific features (`[[ ]]`, arrays, `$RANDOM`, process substitution).
- **Temporary files**: Use `mktemp` for temp files. Flag hardcoded temp paths (`/tmp/myscript.tmp`) which are race-condition-prone.
- **Signal handling**: Long-running scripts should trap signals (`trap cleanup EXIT`) to clean up temporary files and child processes.
