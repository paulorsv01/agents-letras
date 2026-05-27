# Avoid Boolean Prop Proliferation

When a component keeps growing flags like `compact`, `inline`, `minimal`, `editable`, `interactive`,
it is usually hiding multiple components inside one API.

Prefer:

- explicit variant components
- compound components
- composition via children/slots

Bad smell:

```tsx
<Card compact interactive editable bordered />
```

Better:

```tsx
<EditableCard>
  <EditableCard.Header />
  <EditableCard.Body />
</EditableCard>
```
