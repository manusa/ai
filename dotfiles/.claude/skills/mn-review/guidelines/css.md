## CSS Review

- **No `!important`**: Flag `!important` usage. It breaks the cascade and makes styles unmaintainable. Fix specificity issues instead.
- **Modern layout**: Flag `float` for layout purposes. Use flexbox or grid. Flag clearfix hacks.
- **`gap` over margin hacks**: Use `gap` in flex/grid containers instead of `:last-child` margin overrides or negative margins.
- **Responsive design**: Flag hardcoded pixel widths for layout containers. Use relative units (`rem`, `%`, `vw`), `min()`/`max()`/`clamp()`, and media queries.
- **Specificity management**: Flag deeply nested selectors (3+ levels). Flag ID selectors for styling. Keep specificity low and flat.
- **Consistent units**: Flag mixed `px`/`rem`/`em` for the same type of property (e.g., font sizes all in `rem`, not some `px` some `rem`).
- **Custom properties**: Flag repeated magic values (colors, spacing, font sizes). Use CSS custom properties (`--var`) for theming and consistency.
- **Expensive selectors**: Flag universal selectors (`*`), deep descendant selectors, and attribute selectors on large DOMs.
- **Logical properties**: Prefer `margin-inline`, `padding-block`, `inset-inline-start` over directional equivalents (`margin-left`, `padding-top`) for internationalization support.
- **Color syntax**: Prefer modern color syntax (`oklch()`, `hsl()`) over hex for better readability and manipulation. Flag low-contrast color combinations.
