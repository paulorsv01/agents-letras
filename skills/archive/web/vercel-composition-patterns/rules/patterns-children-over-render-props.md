# Prefer Children Over Render Props

If composition can be expressed naturally with children, prefer that over `renderX` props.

Prefer:

```tsx
<PageHeader>
  <PageHeader.Actions>
    <Button />
  </PageHeader.Actions>
</PageHeader>
```

Over:

```tsx
<PageHeader renderActions={() => <Button />} />
```

Render props still make sense when the child truly depends on internal runtime data.
