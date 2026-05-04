# SwiftUI Code Smells

Prioritize these:

1. broad invalidation and observation fan-out
2. unstable identity in `ForEach` / list content
3. expensive derived work in `body`
4. image decode or resize work on the main thread
5. layout thrash from deep geometry/preference chains

Specific smells:

- sorting/filtering inline inside `body`
- `id: \.self` on unstable data
- top-level conditional branch swapping
- large shared observable models read too broadly
- expensive formatter or conversion work recreated during render

Remediation rule:

move work out of `body`, narrow observation scope, stabilize identity, and only use `equatable()` when equality is truly cheaper than recomputation.
