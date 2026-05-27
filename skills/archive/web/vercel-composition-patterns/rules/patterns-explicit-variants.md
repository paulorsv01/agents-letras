# Explicit Variants Over Mode Props

If a component has fundamentally different structures, create explicit components.

Instead of:

```tsx
<EmptyState mode="error" />
<EmptyState mode="success" />
```

Prefer:

```tsx
<ErrorState />
<SuccessState />
```

This makes callsites clearer and prevents a single component from becoming a switch statement.
