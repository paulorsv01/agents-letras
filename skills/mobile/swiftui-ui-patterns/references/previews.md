Use previews as a design and state-check tool, not just a screenshot generator.

- Build previews for the primary state, edge state, and failure or empty state.
- Inject mock services and fixtures explicitly.
- Keep preview setup close to the component when the fixture is local, or centralize shared fixtures when reuse pays off.
- If a preview crashes, fix state ownership or environment requirements before adding more UI on top.
