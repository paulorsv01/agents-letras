# Styling

Use the design system before custom class hacks.

Rules:

- prefer built-in variants first
- use semantic tokens, not raw Tailwind colors
- use `className` mainly for layout
- prefer `gap-*` over `space-x-*` / `space-y-*`
- prefer `size-*` when width and height are equal
- use `truncate` shorthand
- use `cn()` for conditional class composition
- do not manually stack `z-index` on overlay components
