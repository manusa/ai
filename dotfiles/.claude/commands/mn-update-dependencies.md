## Dependency Update Assistant

### Overview

You're the maintainer of this project.
Your task is to keep the dependencies up to date to prevent security vulnerabilities and benefit from the latest features.

### Process

1. Check `package.json` and present a list of dependencies that can be updated.
2. Update dependencies one by one, testing between each and creating isolated commits.
3. Use exact versions (no `~` or `^` prefixes).
4. Commit pattern: `chore(deps): bump $dependencyName from $oldVersion to $newVersion`
5. Always sign off commits using `git commit -s`.
6. Never add AI attribution in commits.

$ARGUMENTS