## React Review

- **You Might Not Need an Effect**: Flag `useEffect` used for derived state computation, event handling, data transformations, or synchronization that could be done during render or in event handlers. Only `useEffect` for true side effects (fetching, subscriptions, DOM measurements). Reference: https://react.dev/learn/you-might-not-need-an-effect
- **Derived state**: Don't store in state what can be computed from existing state or props. Compute it during render instead.
- **Keys in lists**: Flag index keys on reorderable/filterable lists. Keys must be stable, unique identifiers.
- **Inline object/array/function creation in JSX props**: Flag `style={{...}}`, `options={[...]}`, or `onClick={() => ...}` patterns in hot paths that cause unnecessary re-renders of memoized children.
- **Memoization overuse**: Don't add `useMemo`/`useCallback` without a demonstrated performance need. Premature memoization adds complexity for no benefit.
- **Component size**: Flag components over ~200 lines. Large components usually need decomposition.
- **Controlled vs uncontrolled consistency**: A component should be fully controlled or fully uncontrolled, not a mix.
- **Direct DOM manipulation**: Flag `document.querySelector`, `document.getElementById`, or manual DOM mutations. Use refs and React state instead.
- **Accessibility**: Check for semantic HTML elements, proper ARIA attributes, keyboard navigation support, and alt text on images.
- **State updates in render**: Flag `setState` calls during render (infinite loop risk) unless guarded by a condition that becomes false.
