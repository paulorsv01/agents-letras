# Forms

Prefer shadcn form primitives over ad hoc layout.

Rules:

- use `FieldGroup` + `Field` for form structure
- use `FieldSet` + `FieldLegend` for grouped radios/checkboxes/switches
- use `ToggleGroup` for small option sets
- use `InputGroup` helpers instead of absolute-position button hacks
- use proper invalid/disabled attributes on both field and control

If a custom form layout bypasses these primitives, confirm there is a real reason.
