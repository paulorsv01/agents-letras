Use `.task` or `.task(id:)` for lifecycle-driven async work.

- `.task(id:)` is the right default when work should restart for changing inputs.
- Keep cancellation in mind. A restarted task should not leak stale results into the view.
- Debounce externally or in a thin async helper when the input changes rapidly.
- Model loading, success, empty, and error states explicitly instead of sprinkling booleans.
- Avoid hiding service calls deep inside subviews that do not own the user intent.
