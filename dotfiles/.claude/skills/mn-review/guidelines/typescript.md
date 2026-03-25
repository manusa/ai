## TypeScript Review

- **No `any`**: Flag `any` types. Use `unknown` for truly unknown values, or define proper types. `any` defeats the purpose of TypeScript.
- **Avoid type assertions (`as`)**: Prefer type guards, narrowing, or discriminated unions over `as` casts. Assertions silence the compiler without runtime safety.
- **Null/undefined handling**: Use optional chaining (`?.`) and nullish coalescing (`??`). Flag unchecked nullable access.
- **`@ts-ignore` / `@ts-expect-error`**: Flag these without an accompanying comment explaining why the suppression is necessary.
- **Generic constraints**: Ensure generics use `extends` constraints when the function body assumes specific properties (e.g., `<T extends { id: string }>`).
- **Discriminated unions**: Prefer discriminated unions (tagged unions) over broad unions with type assertions for type-safe branching.
- **Promise error handling**: Flag unhandled promise rejections. Every `async` function's errors should be caught at some level.
- **Enum usage**: Prefer `as const` objects or union types over `enum` for better tree-shaking and type inference.
- **Interface vs type consistency**: Flag mixed usage without reason. Pick one convention per project and stick with it.
