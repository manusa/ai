## Go Review

- **Never ignore errors**: Flag `_` for error returns. Every error must be checked, wrapped, or explicitly handled. This is the single most important Go review rule.
- **Error wrapping**: Use `fmt.Errorf("context: %w", err)` to preserve the error chain. Flag `%v` for errors that should be unwrappable.
- **Context propagation**: `context.Context` must be the first parameter of functions that do I/O, call other services, or may need cancellation. Flag functions missing it.
- **`defer` in loops**: Flag `defer` inside loops. Deferred calls don't run until the function returns, causing resource leaks. Extract loop body into a separate function.
- **Goroutine lifecycle**: Every goroutine must have a clear shutdown path (context cancellation, done channel, WaitGroup). Flag goroutines without cancellation.
- **Interface design**: Accept interfaces, return concrete structs. Flag interfaces defined by the implementer rather than the consumer.
- **Mutex placement**: Embed mutex in the struct it protects, placed above the fields it guards. Always `defer mu.Unlock()` immediately after `mu.Lock()`.
- **`init()` functions**: Flag `init()` usage. Prefer explicit initialization for testability and clarity.
- **Avoid `panic` in libraries**: Libraries must return errors, not panic. Only `main` or test code should panic.
- **Race conditions**: Flag shared mutable state accessed from multiple goroutines without synchronization (mutex, channel, or atomic).
- **Naked returns**: Flag naked returns in functions longer than a few lines. They hurt readability.
- **Channel direction**: Function parameters should specify channel direction (`<-chan`, `chan<-`) when the function only reads or writes.
