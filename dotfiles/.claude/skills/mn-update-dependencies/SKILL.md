---
name: mn-update-dependencies
description: Dependency Update Assistant. Checks for outdated dependencies and updates them one by one with isolated commits.
disable-model-invocation: true
---

## Dependency Update Assistant

### Overview

You're the maintainer of this project.
Your task is to keep the dependencies up to date to prevent security vulnerabilities and benefit from the latest features.

### Pre-fetched Context

#### Package Manager Detection
```
!`[ -f package.json ] && echo "npm/yarn (package.json)"; [ -f go.mod ] && echo "go (go.mod)"; [ -f pom.xml ] && echo "maven (pom.xml)"; [ -f build.gradle ] && echo "gradle (build.gradle)"; [ -f build.gradle.kts ] && echo "gradle (build.gradle.kts)"; [ ! -f package.json ] && [ ! -f go.mod ] && [ ! -f pom.xml ] && [ ! -f build.gradle ] && [ ! -f build.gradle.kts ] && echo "No supported package manager detected"`
```

#### Outdated Dependencies (npm)
```
!`[ -f package.json ] && npm outdated 2>/dev/null || echo ""`
```

#### Outdated Dependencies (Go)
```
!`[ -f go.mod ] && go list -m -u all 2>/dev/null | grep '\[' || echo ""`
```

#### Outdated Dependencies (Maven)
```
!`[ -f pom.xml ] && mvn versions:display-dependency-updates -q 2>/dev/null | grep -E "^\[INFO\].*->" | head -30 || echo ""`
```

### Process

1. **Review pre-fetched context**: Check which package manager(s) are detected and what dependencies are outdated.

2. **Present update plan**: Show the user a list of dependencies that can be updated, grouped by:
   - Security updates (prioritize these)
   - Major version updates (may have breaking changes)
   - Minor/patch updates (usually safe)

3. **Update one by one**: For each dependency:
   - Update the dependency
   - Run tests to verify nothing is broken
   - Create an isolated commit

4. **Use exact versions**: No `~` or `^` prefixes for npm. Use exact version constraints.

5. **Commit pattern**: `chore(deps): bump $dependencyName from $oldVersion to $newVersion`

6. **Always sign off**: Use `git commit -s` or `git commit --signoff`.

7. **No AI attribution**: Do not add Co-Authored-By for dependency updates.

### Package-Specific Commands

#### npm / yarn
```shell
# Check outdated
npm outdated

# Update a specific package
npm install <package>@<version> --save-exact

# Run tests
npm test
```

#### Go
```shell
# Check outdated
go list -m -u all | grep '\['

# Update a specific module
go get <module>@<version>

# Tidy up
go mod tidy

# Run tests
go test ./...
```

#### Maven
```shell
# Check outdated (requires versions-maven-plugin)
mvn versions:display-dependency-updates

# Update a specific dependency (edit pom.xml manually or use)
mvn versions:use-latest-versions -Dincludes=<groupId>:<artifactId>

# Run tests
mvn test
```

#### Gradle
```shell
# Check outdated (requires com.github.ben-manes.versions plugin)
gradle dependencyUpdates

# Update: edit build.gradle manually

# Run tests
gradle test
```

### Additional Context
$ARGUMENTS