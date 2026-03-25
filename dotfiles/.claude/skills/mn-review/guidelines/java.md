## Java Review

- **Try-with-resources**: Flag manual `.close()` in `finally` blocks. Use try-with-resources for all `AutoCloseable` resources (streams, connections, readers).
- **Exception handling**: Flag broad `catch (Exception e)` or `catch (Throwable t)`. Catch specific exceptions. Never swallow exceptions with empty catch blocks.
- **Null safety**: Flag `null` returns from methods that could return `Optional`. Use `@Nullable`/`@NonNull` annotations. Flag unchecked dereferences of potentially null values.
- **Thread safety**: Flag shared mutable state without synchronization. Prefer immutable objects. Flag `synchronized` on `this` in public classes (use private lock objects).
- **`equals()`/`hashCode()` contract**: If either is overridden, both must be. Flag violations.
- **Raw types**: Flag raw generic types (e.g., `List` instead of `List<String>`). Raw types bypass compile-time type safety.
- **Stream API misuse**: Flag side effects in `.map()`, `.filter()`. Flag overly complex stream pipelines that would be clearer as loops.
- **Logging**: Flag string concatenation in log statements (use parameterized messages: `log.info("User {}", userId)`). Check log levels are appropriate.
- **Resource management**: Flag `new Thread()` usage. Use `ExecutorService` for thread management. Flag unbounded thread/queue creation.
- **Immutability**: Flag mutable fields in value objects. Prefer `final` fields and unmodifiable collections.
