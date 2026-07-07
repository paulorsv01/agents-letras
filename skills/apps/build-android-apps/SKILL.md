---
name: build-android-apps
description: "Modern Android app work end-to-end — entry point pulling in the official Google Android skills plus Compose best-practices. Compose-first, Navigation 3, edge-to-edge, AGP 9."
---

# Build Android Apps

Umbrella entry point for modern Android work. Invoke this to get the map of the Android bundle, then pull the member skills the task needs. Everything here is Compose-first, Navigation 3, edge-to-edge, AGP 9 — no XML views.

## When to use

- Building, migrating, testing, or profiling an Android app
- Any multi-step Android task spanning UI, build, test, and performance

For a single narrow task, the specific member skill below still applies on its own.

## Member skills — load by phase

**Foundation (official, Google `android/skills`)**
| Skill | Pull in when |
|---|---|
| `android-cli` | Create projects, run apps, manage AVDs, screenshots, UI inspection, docs lookup — the glue for everything |

**UI (official)**
| Skill | Pull in when |
|---|---|
| `navigation-3` | Installing or migrating to Jetpack Navigation 3 (NavKey/NavDisplay, scenes, multi-backstack) |
| `adaptive` | Adaptive UI across phone/tablet/foldable/desktop/TV (requires Compose + Nav3) |
| `edge-to-edge` | Edge-to-edge migration, insets, IME, system-bar legibility (Compose, SDK 35+) |
| `material-3` | MaterialTheme/MD3 tokens, components, dynamic color, theming (Compose-first; lives in the `web` category) |

**Compose authoring & state (best practices, `chrisbanes/skills`)**
| Skill | Pull in when |
|---|---|
| `compose-state-hoisting` | Deciding where UI state lives: local, hoisted, state holder, or ViewModel |
| `compose-state-authoring` | Writing state: `remember { mutableStateOf }`, state lists/maps, read-only composables |
| `compose-state-holder-ui-split` | Splitting a screen composable from its ViewModel/state holder |
| `compose-state-deferred-reads` | Reading scroll/animation/gesture state at the right phase; avoiding back-writes |
| `compose-side-effects` | `LaunchedEffect`, `DisposableEffect`, `rememberCoroutineScope`, `snapshotFlow`, event flows |
| `compose-recomposition-performance` | Investigating recomposition, skippability, compiler reports, Layout Inspector counts |
| `compose-stability-diagnostics` | Parameter stability, compiler reports, strong skipping (Kotlin 2.0+) |
| `compose-modifier-and-layout-style` | Modifier chains, layout APIs, layout wrappers, root layout decisions |
| `compose-slot-api-pattern` | Designing reusable components whose regions vary by caller |
| `compose-animations` | Motion: `AnimatedVisibility`, `animate*AsState`, `AnimatedContent`, `Crossfade`, transitions |
| `compose-focus-navigation` | Focus/D-pad/keyboard navigation for TV, desktop, accessibility |

**Build & optimize (official)**
| Skill | Pull in when |
|---|---|
| `agp-9-upgrade` | Migrating to Android Gradle Plugin 9 (new DSL, built-in Kotlin) — non-KMP projects |
| `r8-analyzer` | Analyzing/optimizing R8 keep rules and ProGuard config |

**Test & profile (official)**
| Skill | Pull in when |
|---|---|
| `testing-setup` | Setting up unit, UI, screenshot, and e2e testing (detects Hilt/Koin, JUnit, Robolectric) |
| `perfetto-trace-analysis` | Root-causing latency, jank, or memory from Perfetto traces |

## How to use

1. Invoke the member skills relevant to the task; you rarely need all at once.
2. Typical flow: `android-cli` (scaffold/run) → `navigation-3` + `adaptive` + `edge-to-edge` (UI shell) → `compose-*` (author screens with correct state/perf) → `testing-setup` (tests) → `agp-9-upgrade` / `r8-analyzer` / `perfetto-trace-analysis` (build, size, perf).
3. Follow each member skill's own guidance; they are the source of truth.

## Note

This is a dispatcher. It holds no rules of its own — the authority lives in the member skills. For Kotlin Multiplatform work, use `build-kmp-apps`.
