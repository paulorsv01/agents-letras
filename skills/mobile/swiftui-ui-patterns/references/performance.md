SwiftUI UI patterns should preserve stable identity and narrow invalidation.

- Prefer stable `ForEach` identities.
- Keep observation scope narrow. Passing a large observable model everywhere broadens updates.
- Use lazy containers for long scroll surfaces.
- Move expensive formatting or derived work out of hot `body` paths.
- If a UI pattern requires heavy gesture math or geometry churn, simplify the interaction before micro-optimizing.
