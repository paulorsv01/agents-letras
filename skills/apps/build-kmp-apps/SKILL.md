---
name: build-kmp-apps
description: "Kotlin Multiplatform (KMP) work end-to-end — entry point pulling in official JetBrains KMP tooling plus expect/actual, routing to the Android and iOS bundles per target."
---

# Build KMP Apps

Umbrella entry point for Kotlin Multiplatform work. Invoke this and load the whole KMP bundle at once. KMP spans a shared Kotlin core plus Android and Apple targets, so this umbrella also routes you to the platform bundles.

## When to use

- Building or migrating a Kotlin Multiplatform project (shared core + Android + iOS)
- Wiring expect/actual boundaries, KMP build/Gradle, or iOS interop

For a single narrow task, the specific member skill below still applies on its own.

## Member skills — load these

**KMP core**
| Skill | Pull in when |
|---|---|
| `compose-multiplatform` | Building shared Compose UI: source-set structure, platform entry points, multiplatform resources, navigation, ViewModel/lifecycle, share-vs-native (house) |
| `kotlin-multiplatform-expect-actual` | Designing expect/actual or interface boundaries for platform services, native SDKs, source sets, files, settings, sensors (`chrisbanes/skills`) |

**KMP tooling (official, JetBrains `Kotlin/kotlin-agent-skills`)**
| Skill | Pull in when |
|---|---|
| `kotlin-tooling-agp9-migration` | Migrating a KMP project to AGP 9 (`com.android.kotlin.multiplatform.library`, module split) — the KMP-specific AGP path |
| `kotlin-tooling-cocoapods-spm-migration` | Moving KMP iOS interop from CocoaPods to Swift Package Manager |
| `kotlin-tooling-java-to-kotlin` | Converting Java to idiomatic Kotlin for shared/common code |

## Platform targets — route to the bundles

| Target | Use |
|---|---|
| Android | `build-android-apps` — Compose UI, Navigation 3, edge-to-edge, Compose best-practices, build/test/profile |
| iOS / Apple | `build-ios-apps` — SwiftUI, Swift Concurrency, Xcode build/run for the iOS target and shared-to-Swift interop |

The Compose authoring skills in `build-android-apps` (`compose-*`) also apply to **Compose Multiplatform** shared UI.

## How to use

1. For project setup or migration, use the KMP tooling skills (`kotlin-tooling-*`). To scaffold a brand-new KMP project, start from the JetBrains KMP wizard (`kmp.jetbrains.com`) or the IDE's KMP template, then continue with `compose-multiplatform` for shared structure.
2. For shared abstractions and platform boundaries, use `kotlin-multiplatform-expect-actual`.
3. For shared UI structure, entry points, resources, and navigation, use `compose-multiplatform`.
4. For each platform's UI and build, route to `build-android-apps` and `build-ios-apps`; the `compose-*` skills apply to shared composables.
5. Follow each member skill's own guidance; they are the source of truth.

## Note

This is a dispatcher. It holds no rules of its own — the authority lives in the member skills and the `build-android-apps` / `build-ios-apps` bundles.
