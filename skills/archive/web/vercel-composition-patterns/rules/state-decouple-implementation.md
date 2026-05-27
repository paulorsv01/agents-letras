# Decouple State Implementation

The provider/root should be the only place that knows how state is stored.

Consumers should read:

- current state
- available actions
- metadata when needed

Consumers should not care whether the internals use:

- `useState`
- reducer
- server actions
- external store

This keeps refactors local and APIs stable.
