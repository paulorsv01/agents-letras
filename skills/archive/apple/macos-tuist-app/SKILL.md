---
name: macos-tuist-app
description: Build, refactor, or review macOS apps that use Tuist and SwiftUI. Use when creating or maintaining macOS utilities or apps with Tuist manifests, layered model-client-store-view architecture, optional LSUIElement menubar behavior, script-based launch flows, or reliable local build/run workflows outside Xcode-first iteration.
---

# macos-tuist-app

Build and maintain macOS apps with a Tuist-first workflow and stable launch scripts. Preserve clear architecture boundaries so networking, state, and UI remain testable and predictable.

## Core Rules

- Treat Tuist manifests as the source of truth. Do not rely on hand-edited generated Xcode artifacts.
- Keep transport and decoding logic outside views. Do not call networking from SwiftUI view bodies.
- Keep state transitions in a store layer (`@Observable` or equivalent), not in presentation code.
- Keep model decoding resilient to API drift: optional fields, safe fallbacks, and defensive parsing.
- Prefer script-based launch for local iteration when `tuist run` is unreliable for macOS target/device resolution.
- Prefer `tuist xcodebuild build` over raw `xcodebuild` in local run scripts when building generated projects.
- For menubar utilities, keep the app menubar-only unless explicitly told otherwise. Use `LSUIElement = true` by default in that case.

## Expected File Shape

Use this placement by default:

- `Project.swift`: app target, settings, resources, `Info.plist` keys
- `Sources/*Model*.swift`: API/domain models and decoding
- `Sources/*Client*.swift`: requests, response mapping, transport concerns
- `Sources/*Store*.swift`: observable state, refresh policy, filtering, caching
- `Sources/*App*.swift` or `Sources/*Scene*.swift`: app entry, scene wiring, dependency injection
- `Sources/*View*.swift`: screen, panel, or menu composition
- `Sources/*Row*View*.swift`: row rendering and lightweight interactions when list/menu rows exist
- `run-app.sh` or `run-menubar.sh`: canonical local restart/build/launch path
- `stop-app.sh` or `stop-menubar.sh`: explicit stop helper when needed

## Workflow

1. Confirm Tuist ownership
- Verify `Tuist.swift` and `Project.swift` (or workspace manifests) exist.
- Read existing run scripts before changing launch behavior.

2. Confirm app mode before changing lifecycle
- Check whether the app is a standard windowed app, a menu bar utility, or a hybrid.
- If it is menubar-only, preserve `LSUIElement` behavior unless explicitly asked to change it.

3. Probe backend behavior before coding assumptions
- Use `curl` to verify endpoint shape, auth requirements, and pagination behavior.
- If an endpoint ignores `limit/page`, implement full-list handling with local trimming in the store.

4. Implement layers from bottom to top
- Define or adjust models first.
- Add or update client request and decoding logic.
- Update store refresh, filtering, cache policy, and derived state.
- Wire views last.

5. Keep app wiring minimal
- Keep app entry focused on scene wiring and dependency injection.
- Avoid embedding business logic in `App`, scene declarations, or menu definitions.

6. Standardize launch ergonomics
- Ensure the run script restarts an existing instance before relaunching.
- Ensure the run script does not open Xcode as a side effect.
- Use `tuist generate --no-open` when generation is required.
- When the run script builds the generated project, prefer `TUIST_SKIP_UPDATE_CHECK=1 tuist xcodebuild build ...` instead of invoking raw `xcodebuild` directly.

## Validation Matrix

Run validations after edits:

```bash
TUIST_SKIP_UPDATE_CHECK=1 tuist xcodebuild build -scheme <TargetName> -configuration Debug
```

If launch workflow changed:

```bash
./run-app.sh
```

If the project uses menubar-specific scripts:

```bash
./run-menubar.sh
```

If shell scripts changed:

```bash
bash -n run-app.sh
bash -n stop-app.sh
```

If the project uses menubar-specific scripts, also run:

```bash
bash -n run-menubar.sh
bash -n stop-menubar.sh
./run-menubar.sh
```

## Failure Patterns and Fix Direction

- `tuist run` cannot resolve the macOS destination:
Use run and stop scripts as the canonical local run path.

- UI is laggy or inconsistent after refresh:
Move derived state and filtering into the store; keep views render-only.

- API payload changes break decode:
Relax model decoding with optional fields and defaults, then surface missing data safely in UI.

- Feature asks for a quick UI patch:
Trace the root cause in model, client, or store before changing presentation code.

- App mode drifts accidentally from menubar to windowed, or the reverse:
Check `Info.plist` keys, scene declarations, and run scripts together before changing UI structure.

## Completion Checklist

- Keep Tuist manifests and run scripts aligned with the actual build and run flow.
- Keep network and state logic out of SwiftUI view bodies.
- Preserve the current app mode unless explicitly asked to change it.
- Run the validation matrix for touched areas.
- Report concrete commands run and outcomes.
