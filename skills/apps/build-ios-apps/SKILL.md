---
name: build-ios-apps
description: "End-to-end Apple-platform app work — single entry point that pulls in the SwiftUI, Swift Concurrency, and Xcode build/test/run skills. Use when building, running, debugging, or shipping an iOS, macOS, watchOS, tvOS, or visionOS app."
---

# Build iOS Apps

Umbrella entry point for Apple-platform app work. Invoke this to see the full Apple-platform bundle in one place, then load the members relevant to the task instead of discovering them one by one.

## When to use

- Building or extending an iOS, macOS, watchOS, tvOS, or visionOS app
- Any multi-step Apple-platform task that spans UI, concurrency, and build/run

For a single narrow task, the specific member skill below still applies on its own.

## Member skills — load these

**Core (adapted — AvdLee/Dimillian MIT; `xcodebuildmcp-cli` verbatim getsentry/XcodeBuildMCP MIT)**
| Skill | Pull in when |
|---|---|
| `swiftui` | Building or refactoring views, state, navigation, accessibility, performance traces, Liquid Glass |
| `swift-concurrency` | async/await, actors, tasks, Sendable, data races, isolation, Swift 6 migration |
| `xcodebuildmcp-cli` | Build, test, run, debug, logs, and UI automation via the XcodeBuildMCP CLI |

**System integration & diagnostics (openai/plugins — no explicit upstream license)**
| Skill | Pull in when |
|---|---|
| `ios-app-intents` | Exposing app actions or content to Shortcuts, Siri, Spotlight, widgets, or controls (App Intents, App Entities) |
| `ios-ettrace-performance` | Profiling launch or runtime latency on Simulator, comparing traces, finding CPU-heavy stacks (ETTrace) |
| `ios-memgraph-leaks` | Debugging leaked objects, retain cycles, or memory growth with before/after leak evidence (memgraph) |

**Persistence & testing (MIT)**
| Skill | Pull in when |
|---|---|
| `swiftdata-pro` | SwiftData: `@Model`, `@Query`, `#Predicate`, migrations, `@ModelActor`, CloudKit |
| `swift-testing-expert` | Swift Testing (`@Test`/`#expect`), traits/tags, parameterized tests, XCTest migration |

**Granular depth (dpearson2699 — PolyForm, private use only)**
| Skill | Pull in when |
|---|---|
| `swiftui-navigation` | Dedicated NavigationStack/SplitView, sheets, tabs, programmatic routing, deep linking |
| `swift-architecture` | Choosing/migrating MV vs MVVM/MVI/TCA/Clean/Coordinator for a feature |
| `ios-accessibility` | Deep VoiceOver/Switch/Voice Control, Dynamic Type, rotors, a11y audits |
| `swiftui-animation` | PhaseAnimator/KeyframeAnimator, springs, matched transitions, SF Symbol effects, reduce-motion |
| `swiftui-gestures` | Gesture composition/conflicts, `@GestureState`, MagnifyGesture/RotateGesture |

**State & Observation (house)**
| Skill | Pull in when |
|---|---|
| `swiftui-state-and-observation` | Where state lives (`@State`/`@Binding`/`@Bindable`/`@Environment`), `@Observable` models, single source of truth, re-render granularity |

> `swiftui` is the broad survey skill; the granular skills above go deeper per topic. Prefer the granular one for focused work.

## How to use

1. Invoke the member skills relevant to the task; you rarely need all at once.
2. Default loop: implement with `swiftui` + `swift-concurrency`, then build, test, and run with `xcodebuildmcp-cli`.
3. Follow each member skill's own guidance; they are the source of truth.

## Note

This is a dispatcher. It holds no rules of its own — the authority lives in the member skills. Keep them as the source of truth and update them, not this file. For Kotlin Multiplatform work (shared Kotlin core with an iOS target), use `build-kmp-apps`.
