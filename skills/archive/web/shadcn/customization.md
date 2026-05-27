# Customization

- Extend shadcn through theme tokens, CSS variables, and composition before forking component internals.
- Respect the project's configured `style`, `base`, `iconLibrary`, and resolved aliases from `shadcn info`.
- Put design system changes in the real global CSS/theme entry points. Do not create parallel token files unless the project already does that.
- Prefer variants and semantic tokens over raw utility overrides on component instances.
- When a customization needs repeated structural changes, turn it into a local wrapper component instead of one-off class churn.
