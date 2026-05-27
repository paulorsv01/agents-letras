# Context Interface

Design context values as a small interface:

- state
- actions
- optional meta

Example:

```ts
type DialogContextValue = {
  isOpen: boolean
  open: () => void
  close: () => void
}
```

Avoid dumping unrelated derived values and helpers into one giant context object.
