# Base vs Radix

Check the project's `base` field before assuming the API.

Key differences:

- trigger composition may use `asChild` or `render`
- `Select`, `ToggleGroup`, `Slider`, and `Accordion` props differ
- some base variants support object values or `multiple` in places where radix does not

Never cargo-cult examples from one base into the other without checking.
