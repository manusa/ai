---
name: mn-agents-md
description: AGENTS.md Generator. Creates or updates AGENTS.md file for AI coding agents with project-specific instructions, testing guidelines, and development commands.
argument-hint: "[optional focus areas]"
disable-model-invocation: true
allowed-tools: Bash
---

## AGENTS.md Generator

### Overview

You're helping to create or update the `AGENTS.md` file for this project.
The `AGENTS.md` file provides comprehensive guidance for AI coding agents (GitHub Copilot, Claude Code, Gemini, etc.) to work effectively with this codebase.

### Pre-fetched Context

#### AGENTS.md Status
```
!`~/.claude/skills/mn-agents-md/scripts/check-agents-md.sh`
```

#### CLAUDE.md Symlink Status
```
!`~/.claude/skills/mn-agents-md/scripts/check-claude-md.sh`
```

#### Project Type Detection
```
!`~/.claude/skills/mn-agents-md/scripts/detect-project-type.sh`
```

#### Project Information
```
!`~/.claude/skills/mn-agents-md/scripts/get-project-info.sh`
```

#### README Summary
```
!`~/.claude/skills/mn-agents-md/scripts/get-readme-summary.sh`
```

### Mode Determination

Based on the pre-fetched context:
- If **AGENTS.md Status** shows `EXISTS`: You are in **UPDATE MODE** - review and update the existing file
- If **AGENTS.md Status** shows `NOT_FOUND`: You are in **CREATE MODE** - create a new file from the template

### Template Structure

Use the following template structure. Adapt sections based on the detected project type.
Fill in the placeholders based on project analysis.

```markdown
# [Project Name] - AI Agents Instructions

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

This file provides guidance to AI coding agents (GitHub Copilot, Claude Code, etc.) when working with code in this repository.

## Project Overview

[1-3 sentences describing what the project does, its purpose, and key technologies]

## Working Effectively

### Bootstrap and Setup
[Installation/setup commands with timing information]

### Build Commands
[Build/compile commands with timing information]

### Testing
[Test commands with timing information - CRITICAL: Include timing and NEVER CANCEL warnings for long-running commands]

### Running the Application
[How to run/start the application]

## Architecture

### Technical Structure
[Directory layout and key components]

### Design Patterns
[Key architectural decisions and patterns used]

## Code Style

[Linting, formatting, and naming conventions]

## Testing Guidelines

[See "Testing Philosophy" section below for required content]

## Common Tasks

[Frequently performed development operations]

## Troubleshooting

[Known issues and their solutions]
```

### Testing Philosophy

**CRITICAL**: Include these testing principles in the Testing Guidelines section:

1. **Black-box Testing**: Tests should verify behavior and observable outcomes, not implementation details. Test the public API only.

2. **Avoid Mocks**: Use real implementations and test infrastructure whenever possible. Mocks should be a last resort.

3. **Nested Test Structure**:
   - **JavaScript (Jest/Vitest)**: Nested `describe` blocks
   - **Java (JUnit)**: `@Nested` annotations with inner classes
   - **Go**: Subtests with `t.Run()`
   - **Python (pytest)**: Nested classes or fixtures

4. **Scenario-Based Setup**:
   - Define common scenario in the outer `beforeEach`/`beforeAll` (or equivalent)
   - Define specific conditions for nested scenarios in the nested block's setup
   - The tested function/behavior should often be called in the `beforeEach`/setup block

5. **Single Assertion Per Test**:
   - Each test block should assert ONE specific condition
   - This provides clear failure identification
   - Example: Instead of testing multiple conditions in one test, split into multiple focused tests

**Example structures by language:**

#### JavaScript (Jest)
```javascript
describe('UserService', () => {
  let service;
  beforeEach(() => {
    service = new UserService();
  });

  describe('createUser', () => {
    describe('with valid input', () => {
      let result;
      beforeEach(async () => {
        result = await service.createUser({ name: 'John', email: 'john@example.com' });
      });

      test('returns the created user', () => {
        expect(result.name).toBe('John');
      });

      test('assigns an id', () => {
        expect(result.id).toBeDefined();
      });
    });

    describe('with invalid email', () => {
      let error;
      beforeEach(async () => {
        try {
          await service.createUser({ name: 'John', email: 'invalid' });
        } catch (e) {
          error = e;
        }
      });

      test('throws an error', () => {
        expect(error).toBeInstanceOf(ValidationError);
      });
    });
  });
});
```

#### Java (JUnit 5)
```java
class UserServiceTest {
    private UserService service;

    @BeforeEach
    void setUp() {
        service = new UserService();
    }

    @Nested
    class CreateUser {
        @Nested
        class WithValidInput {
            private User result;

            @BeforeEach
            void setUp() {
                result = service.createUser("John", "john@example.com");
            }

            @Test
            void returnsTheCreatedUser() {
                assertThat(result.getName()).isEqualTo("John");
            }

            @Test
            void assignsAnId() {
                assertThat(result.getId()).isNotNull();
            }
        }

        @Nested
        class WithInvalidEmail {
            @Test
            void throwsValidationException() {
                assertThatThrownBy(() -> service.createUser("John", "invalid"))
                    .isInstanceOf(ValidationException.class);
            }
        }
    }
}
```

#### Go
```go
func TestUserService(t *testing.T) {
    service := NewUserService()

    t.Run("CreateUser", func(t *testing.T) {
        t.Run("with valid input", func(t *testing.T) {
            result, err := service.CreateUser("John", "john@example.com")
            require.NoError(t, err)

            t.Run("returns the created user", func(t *testing.T) {
                assert.Equal(t, "John", result.Name)
            })

            t.Run("assigns an id", func(t *testing.T) {
                assert.NotEmpty(t, result.ID)
            })
        })

        t.Run("with invalid email", func(t *testing.T) {
            _, err := service.CreateUser("John", "invalid")

            t.Run("returns an error", func(t *testing.T) {
                assert.Error(t, err)
            })
        })
    })
}
```

### Process

1. **Analyze the pre-fetched context** to understand:
   - Whether to create or update
   - The project type(s) detected
   - The project structure and purpose

2. **Explore the codebase** if needed:
   - Read key configuration files (package.json, go.mod, pom.xml, etc.)
   - Understand the directory structure
   - Identify testing frameworks and patterns

3. **Generate or update the AGENTS.md**:
   - Use the template structure above
   - Adapt sections to the detected project type
   - Include accurate timing information for commands
   - Add project-specific details

4. **Handle the CLAUDE.md symlink**:
   - If **CLAUDE.md Symlink Status** shows `NOT_FOUND`: Create symlink with `ln -s AGENTS.md CLAUDE.md`
   - If it shows `SYMLINK -> AGENTS.md`: No action needed
   - If it shows `FILE (not a symlink)`: Warn the user and ask how to proceed

5. **Review with the user**:
   - Present the generated/updated content
   - Ask for confirmation before writing
   - Make adjustments based on feedback

### Commands

```shell
# Create CLAUDE.md symlink (after AGENTS.md is created)
ln -s AGENTS.md CLAUDE.md

# Verify symlink
ls -la CLAUDE.md
```

### Additional Context
$ARGUMENTS