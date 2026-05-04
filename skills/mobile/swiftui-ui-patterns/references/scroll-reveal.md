Use scroll-driven reveal patterns when secondary UI should emerge from scrolling rather than separate gesture state.

- Derive one normalized progress value from scroll offset.
- Drive opacity, scale, blur, or positional changes from that single source of truth.
- Avoid competing gesture and scroll state machines unless scroll alone cannot express the interaction.
- Keep reveal thresholds explicit and predictable.
