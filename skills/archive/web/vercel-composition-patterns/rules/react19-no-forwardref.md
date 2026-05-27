# React 19: Reconsider `forwardRef`

If the project is already on React 19 patterns, avoid cargo-culting `forwardRef` into every component.

Only use ref plumbing when the component actually exposes imperative focus/measurement behavior.

Do not introduce ref complexity for plain presentational components.
