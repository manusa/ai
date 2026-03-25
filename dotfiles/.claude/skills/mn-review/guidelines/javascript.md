## JavaScript Review

- **Strict equality**: Flag `==` and `!=`. Use `===` and `!==` to avoid type coercion bugs.
- **`const`/`let` over `var`**: Flag `var` declarations. Use `const` by default, `let` only when reassignment is needed.
- **Promise handling**: Every promise chain must have a `.catch()` or be inside a `try/catch` with `await`. Flag fire-and-forget promises.
- **Implicit globals**: Flag variables used without declaration. Missing `const`/`let` creates global variables.
- **Prototype pollution**: Flag bracket notation property assignment from user input (e.g., `obj[userInput] = value`) without safeguards against `__proto__`, `constructor`, `prototype`.
- **Error handling**: Flag empty `catch` blocks. At minimum, log the error. Don't silently swallow failures.
- **Optional chaining**: Use `?.` and `??` instead of verbose `&&` chains or ternaries for nested property access.
- **Array mutation**: Flag `.sort()`, `.reverse()` on arrays that shouldn't be mutated in place. Use `.toSorted()`, `.toReversed()`, or spread first.
