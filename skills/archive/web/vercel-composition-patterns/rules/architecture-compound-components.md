# Compound Components

Use compound components when a complex widget has shared state and multiple subparts.

Good candidates:

- tabs
- dropdowns
- steppers
- command palettes
- filters with shared selection state

Goal:

- one root owns state
- children express structure
- consumers compose only what they need

Prefer readable usage over clever abstractions.
