---
name: componentize
description: Extract and organize existing UI into reusable components with thoughtful APIs.
---

# Componentize

Use this when the user wants to componentize, extract, or organize UI code into reusable components.

## Activation

### Use For

- componentizing an existing page, section, or prototype
- extracting a page or section into components
- extracting repeated UI into reusable components
- reducing duplication in UI code
- turning a draft implementation into production-ready code structure
- splitting a large UI file into smaller, focused modules

### Do Not Use For

- brand-new design or layout work
- visual polish without code structure changes
- Tailwind class cleanup without component extraction
- responsive behavior, dark mode, or image adaptation only

## Load First

- No companion modules are required.

## Progress Updates

Keep the user informed so longer runs do not look stuck.

- One-line status update before each major phase.
- Concrete and lightweight: what you are doing now, not verbose logs.

## Workflow

1. Inspect existing project component patterns before creating new components.
2. Identify repeated patterns, logical sections, and self-contained UI blocks.
3. Extract components with call-site spacing and configurable class merging.
4. Reuse or extend existing project components where available.
5. Re-scan extracted components for remaining duplication.

## Rules

- Break designs into small, focused components instead of rendering everything in a single large component — extract repeated patterns, logical sections, and self-contained UI blocks into their own components
- Never bake margins into components — apply margins at the call site instead; every component must accept the framework's class prop (`className` in React, `class` in Vue/Svelte/Astro) and merge it into the component's top-level element
- Merge classes with the project's existing helper (commonly `cn` = clsx + tailwind-merge); in Tailwind projects use `tailwind-merge` so caller classes actually override component defaults. Applies to server and client components alike.
- Define extracted components at module top level — never inside another component's function body (in React this remounts the subtree every render and destroys state/focus). When the extracted block owns state, hooks, refs, or keys, move them with it or hoist state to the parent deliberately; verify no state/focus loss after extraction.
- Design prop APIs deliberately: prefer `children`/slots over string props for variable content; model visual variations as a small `variant`/`size` prop instead of accumulating boolean flags; keep the prop surface minimal and pass native element attributes through (rest props) on the top-level element.
- Always extract form controls into reusable components organized by HTML element — one `Input` for all text-like `<input>` types (text, email, password, number, search, url, tel), one `Select` for `<select>`, one `Textarea` for `<textarea>`; `checkbox`, `radio`, and `range` are separate components by convention (Checkbox, Radio/RadioGroup, Slider); never create type-specific components like `EmailInput` or `PasswordInput`; check the project for existing ones before creating new ones
- When two or more elements share the same structure and styling but differ only in props like labels, placeholders, or types — extract them into a single reusable component parameterized by those differences
- After extracting components, scan them for duplicated patterns and extract shared elements into reusable components — e.g. repeated section container/max-width/padding wrappers, repeated heading group structures (eyebrow + heading + subheading), repeated card shells, repeated button styles
- Always use existing project components when they are available — reuse or extend them instead of creating new ones; buttons and form elements are especially common candidates

## Verify

- Run relevant formatting, lint, typecheck, or tests when available.
- Render the affected pages before/after (dev server or screenshot) and diff visually; confirm interactive elements (forms, focus, toggles) still work; extraction must produce zero visual or behavioral change.
