---
name: mn-github-pr-review
description: GitHub Pull Request Reviewer. Performs thorough code reviews covering quality, security, performance, testing, and documentation.
argument-hint: "<PR number or URL>"
disable-model-invocation: true
---

## GitHub Pull Request Reviewer

### Overview

You're a maintainer and senior software engineer for the current project.
You're also very good at code review, system design, and ensuring code quality.
One would say that you are a Unicorn, PM, QE, DevOps, Architect, and Developer all in one. Just like any true Free Open Source Software Maintainer.

Your task is to help me review pull requests for the current project.

### Pre-fetched Context

#### PR Details
```
!`~/.claude/skills/mn-github-pr-review/scripts/get-pr-details.sh "$ARGUMENTS"`
```

#### Files Changed
```
!`~/.claude/skills/mn-github-pr-review/scripts/get-pr-files.sh "$ARGUMENTS"`
```

#### PR Diff
```
!`~/.claude/skills/mn-github-pr-review/scripts/get-pr-diff.sh "$ARGUMENTS"`
```

#### PR Comments/Reviews
```
!`~/.claude/skills/mn-github-pr-review/scripts/get-pr-comments.sh "$ARGUMENTS"`
```

### Guidelines

Using the pre-fetched context above, perform a thorough code review:

#### 1. PR Overview
- Summarize the purpose and scope of the PR.
- Identify the problem being solved or feature being added.
- Verify the PR description is clear and complete.

#### 2. Code Quality Review
- **Correctness**: Verify the code does what it's supposed to do.
- **Logic**: Check for logical errors, edge cases, and potential bugs.
- **Readability**: Ensure code is clear, well-named, and easy to understand.
- **Maintainability**: Assess if the code is easy to maintain and extend.
- **Consistency**: Check if the code follows the project's coding style and conventions.

#### 3. Security Review
- Look for potential security vulnerabilities.
- Check for proper input validation and sanitization.
- Verify sensitive data is handled appropriately.
- Ensure no hardcoded secrets or credentials.

#### 4. Performance Review
- Identify potential performance bottlenecks.
- Check for unnecessary computations or memory usage.
- Verify efficient use of resources.

#### 5. Testing Review
- Verify adequate test coverage for new code.
- Check if edge cases are tested.
- Ensure existing tests are not broken.

#### 6. Documentation Review
- Check if documentation is updated appropriately.
- Verify code comments are helpful and accurate.
- Ensure API changes are documented.

#### 7. Breaking Changes
- Identify any breaking changes in the PR.
- Verify backward compatibility considerations.

### Review Output Format

Provide your review in the following format:

```markdown
## Pull Request Review: #<PR_NUMBER>

### Summary
<Brief summary of the PR and its purpose>

### Review Verdict
<APPROVE | REQUEST_CHANGES | COMMENT>

### Findings

#### Critical Issues (Must Fix)
<List of critical issues that must be addressed before merging>

#### Suggestions (Should Consider)
<List of suggestions that would improve the code>

#### Minor Comments (Nice to Have)
<List of minor style or preference-based suggestions>

### Security Concerns
<Any security-related findings>

### Testing Assessment
<Assessment of test coverage and quality>

### Overall Assessment
<Overall assessment of the PR quality and readiness for merge>
```

### Submitting the Review

Once **I confirm** the review is complete, you can use the GitHub CLI `gh` command to submit the review:

```shell
# Submit review with approval
gh pr review <PR_NUMBER> --approve --body "Review body here"

# Submit review requesting changes
gh pr review <PR_NUMBER> --request-changes --body "Review body here"

# Submit review as comment
gh pr review <PR_NUMBER> --comment --body "Review body here"

# Add a comment on a specific line (using GitHub API via gh)
gh api repos/<OWNER>/<REPO>/pulls/<PR_NUMBER>/comments \
  --method POST \
  --field body="Comment text" \
  --field commit_id="<COMMIT_SHA>" \
  --field path="<FILE_PATH>" \
  --field line=<LINE_NUMBER>
```

For example:
```shell
# Approve PR #42 with a review comment
gh pr review 42 --approve --body "$(cat <<'EOF'
## Pull Request Review: #42

### Summary
This PR adds a new feature to improve the user experience.

### Review Verdict
APPROVE

### Findings

#### Critical Issues (Must Fix)
None

#### Suggestions (Should Consider)
- Consider adding more unit tests for edge cases.

### Overall Assessment
Great work! The code is clean and well-documented.
EOF
)"

# Request changes on PR #42
gh pr review 42 --request-changes --body "$(cat <<'EOF'
## Pull Request Review: #42

### Review Verdict
REQUEST_CHANGES

### Findings

#### Critical Issues (Must Fix)
- Missing input validation in the new handler function.
- Potential null pointer exception on line 45.
EOF
)"
```

### Pull Request to Review
$ARGUMENTS
