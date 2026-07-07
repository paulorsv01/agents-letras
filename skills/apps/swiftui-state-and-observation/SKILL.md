---
name: swiftui-state-and-observation
description: "Use when deciding where SwiftUI state lives and how Observation tracks it — @State, @Binding, @Bindable, @Environment, @Observable models, single source of truth, and re-render granularity."
---

# SwiftUI State and Observation

Decide where each piece of state lives and let the Observation framework (`@Observable`) drive precise view updates. The goal is one source of truth per value, the narrowest ownership that works, and views that re-render only when the data they actually read changes.

## Activation

### Use For

- Choosing the right tool for a value: `@State`, `@Binding`, `@Bindable`, `@Environment`, or a plain property
- Designing an `@Observable` model and deciding what it owns
- Fixing over-rendering or stale state caused by misplaced ownership
- Migrating `ObservableObject` / `@StateObject` / `@ObservedObject` / `@Published` / `@EnvironmentObject` to Observation
- Reasoning about which property reads trigger a view update (observation granularity)

### Do Not Use For

- Choosing an app architecture pattern (MV vs MVVM vs TCA) → use `swift-architecture`
- Routing, `NavigationStack`, or deep links → use `swiftui-navigation`
- Persistence, `@Model`, `@Query` → use `swiftdata-pro` (SwiftData's `@Model` is already `@Observable`)
- General SwiftUI view building, layout, or modifiers → use `swiftui`
- Concurrency, actors, `@MainActor` isolation of models → use `swift-concurrency`

## Workflow

1. Identify the value and ask who owns it. Owned-and-mutated-here → `@State`. Owned by a parent, mutated here → `@Binding`. Shared across a subtree → `@Environment`.
2. If the value is a model object (reference type) with behavior, mark the type `@Observable` and have exactly one view own the instance with `@State`.
3. Pass the model down as a plain `let` property for read-only use; use `@Bindable` only where you need two-way `$model.property` bindings.
4. Inject app- or feature-wide models through `@Environment(Model.self)`.
5. Check granularity: confirm each view's `body` reads only the properties it needs, so unrelated mutations don't invalidate it.
6. Remove any legacy `ObservableObject` machinery the change orphaned.

## Rules

### Ownership decision (single source of truth)

- `@State private var` — the view creates and owns the value (value type) or the model instance (reference type). Keep it `private`.
- `@Binding var` — a read/write reference to state owned by an ancestor; never a source of truth itself. Create bindings with `$`.
- `@Environment(Type.self) private var model` — read a model injected higher up; inject with `.environment(model)`. The non-optional form traps at runtime if the model was never injected; declare the property as `Model?` when injection is conditional.
- A plain `let model: Model` parameter is correct when a child only reads an `@Observable` model — no wrapper needed for observation to work.
- Exactly one owner per value. If two views both need to mutate it, hoist ownership to their common ancestor and pass `@Binding` down.

### @Observable models

- Annotate model classes with `@Observable` (from `import Observation`); make them `final`.
- Do not add `@Published` — Observation tracks all stored properties automatically. Do not conform to `ObservableObject`.
- Own an `@Observable` instance with `@State` (not `@StateObject`, which is for `ObservableObject`).
- Use `@Bindable var model = …` (or `@Bindable` on a parameter) to get `$model.property` bindings for controls like `TextField`.
- When a model comes from `@Environment` and you need bindings, `@Bindable` cannot be combined with `@Environment` on the same property; instead create a local wrapper inside `body` — `@Bindable var model = model` — then use `$model.property`.
- Mark a property `@ObservationIgnored` only when it must not participate in tracking (e.g. caches, non-UI bookkeeping).

### Observation granularity

- A view's `body` is re-evaluated only when a stored property it actually reads during `body` changes. Reading fewer properties means fewer invalidations.
- Push reads down: let leaf views read the specific properties they display, instead of a parent reading the whole model and passing primitives.
- Computed properties are tracked through the stored properties they read.
- For non-view reactions to model changes, use `withObservationTracking(_:onChange:)` rather than polling — note `onChange` is one-shot (re-register inside the handler for continuous tracking) and fires before the new value is set; on newer SDKs (Swift 6.2 / iOS 26+) prefer the `Observations` `AsyncSequence` for streams of changes.

### Deriving vs storing

- Derive values during `body` or as computed properties; do not duplicate derived data into stored `@State` that can drift.
- Store only the minimal independent state; everything else is a function of it.

### Migration from ObservableObject

- Requires deployment targets of iOS 17 / macOS 14 or later; below that, `ObservableObject` must stay.
- `class VM: ObservableObject { @Published var x }` → `@Observable final class VM { var x }`.
- `@StateObject private var vm = VM()` → `@State private var vm = VM()`. `@State` evaluates its initial value on every container init (result discarded after the first) — keep `@Observable` initializers cheap, or create the model outside the view and pass it in.
- `@ObservedObject var vm` → plain `let vm` (read-only) or `@Bindable var vm` (needs bindings).
- `@EnvironmentObject var vm` → `@Environment(VM.self) private var vm`, and `.environmentObject(vm)` → `.environment(vm)`.
- Remove `import Combine` if it was only used for `@Published`/`ObservableObject`.

## Verify

- Each value has exactly one owner; children receive `@Binding`/`@Environment`/plain reads, not duplicate `@State`.
- Models are `@Observable final class`, owned with `@State`, with no `@Published`/`ObservableObject`.
- `@Bindable` appears only where two-way bindings are actually used.
- No `@StateObject`/`@ObservedObject`/`@EnvironmentObject`/`@Published` remain after a migration; `import Combine` removed if now unused.
- Spot-check a hot view: mutating an unrelated model property does not re-evaluate its `body`. Add `let _ = Self._printChanges()` at the top of the view's `body` (or use the Instruments SwiftUI template's View Body track) to confirm the body is not re-evaluated when the unrelated property mutates.
