---
name: compose-multiplatform
description: "Use when building shared UI for Kotlin Multiplatform with Compose Multiplatform — shared composables, multiplatform resources, navigation, ViewModel/lifecycle, platform entry points, and share-vs-native decisions."
---

# Compose Multiplatform

Build one Compose UI in `commonMain` and run it on Android, iOS, desktop, and web. Maximize shared composables, keep platform code at the thin entry-point and capability edges, and use the multiplatform-aware resource, navigation, and ViewModel libraries rather than Android-only ones.

## Activation

### Use For

- Structuring shared composables and source sets for a Compose Multiplatform app
- Wiring multiplatform resources, navigation, ViewModel, and lifecycle in `commonMain`
- Writing per-platform entry points (iOS / Android / desktop / web)
- Deciding what UI to share vs implement natively per platform
- Handling platform-specific UI behavior differences (keyboard, gestures, back, text rendering)

### Do Not Use For

- `expect`/`actual` mechanics and platform-service boundaries in general → use `kotlin-multiplatform-expect-actual`
- AGP / Gradle / KMP module migration → use `kotlin-tooling-agp9-migration`
- KMP iOS interop (CocoaPods → SPM) → use `kotlin-tooling-cocoapods-spm-migration`
- Android-only Compose authoring (state, recomposition, modifiers, animation) → use the `compose-*` skills; they apply to shared composables too
- Native SwiftUI screens on the iOS side → use the iOS skills via `build-ios-apps`

## Workflow

1. Put shared UI in `commonMain`; add platform source sets (`androidMain`, `iosMain`, `desktopMain`/`jvmMain`, `wasmJsMain`) only for entry points and platform capabilities.
2. Depend on the JetBrains multiplatform Gradle coordinates (`org.jetbrains.compose.*`, `org.jetbrains.androidx.*`), not the Android-only `androidx.compose.*` coordinates, in common code; source imports still use `androidx.compose.*` packages. Apply the `org.jetbrains.compose` and `org.jetbrains.kotlin.plugin.compose` (Compose compiler, mandatory since Kotlin 2.0, matching the Kotlin version) Gradle plugins alongside the KMP plugin.
3. Define a single root composable (e.g. `App()`) in `commonMain` and mount it from each platform entry point.
4. Move images, strings, fonts into the resources system and access them through the generated `Res`.
5. Add navigation with the multiplatform `navigation-compose`, routes as `@Serializable` types.
6. Hoist screen state into ViewModels in common code; inject dependencies with a KMP-capable DI (Koin or Metro).
7. Verify each platform's default behaviors (keyboard insets, gestures, back) and only branch per platform where the UX genuinely differs.

## Rules

### Project structure

- Shared composables, navigation, and ViewModels live in `commonMain`. Keep `xxxMain` source sets minimal.
- Use the `org.jetbrains.compose` (Compose Multiplatform) Gradle coordinates, Material 3, and the JetBrains `org.jetbrains.androidx.*` library coordinates in common code; reserve the Android-only `androidx.*` artifact coordinates for `androidMain`. Source imports in common code still use `androidx.compose.*` packages.

### Platform entry points (mount the shared root)

- Android: `setContent { App() }` in a `ComponentActivity`.
- iOS: `ComposeUIViewController { App() }` (from `androidx.compose.ui.window`), wrapped in a SwiftUI `UIViewControllerRepresentable` or used directly.
- Desktop (JVM): `application { Window(onCloseRequest = ::exitApplication) { App() } }` (or `singleWindowApplication`).
- Web (Wasm/JS): `ComposeViewport(document.body!!) { App() }` (CMP 1.9+ also has a no-arg `ComposeViewport { App() }` overload).

### Resources

- Configure the `compose.resources` Gradle block; access assets through the generated `Res` class: `painterResource(Res.drawable.x)`, `stringResource(Res.string.y)`, `Font(Res.font.z)`.
- Since Compose Multiplatform 1.6.10, resources can live in any Gradle module and source set. Set `publicResClass` when a library must expose its `Res`.
- `painterResource()` is synchronous on all targets except web, where the first recomposition returns an empty painter — account for it.

### Navigation

- Use `org.jetbrains.androidx.navigation:navigation-compose`; create with `rememberNavController()` and a `NavHost(startDestination = …)`.
- Define routes as `@Serializable` data objects/classes and use type-safe `composable<Route> { }` + `navController.navigate(Route(id))`.
- Pass only minimal data (IDs, primitives) through routes — never ViewModels or large objects.
- On web, call `navController.bindToBrowserNavigation()` (experimental — requires `@OptIn(ExperimentalBrowserHistoryApi::class)`) so Back/Forward and the address bar reflect the route; use `@SerialName` for readable URLs.
- For Navigation 3 (experimental/alpha in CMP), add the core multiplatform artifacts `org.jetbrains.androidx.navigation3:navigation3-runtime` and `navigation3-ui`, plus the companion `lifecycle-viewmodel-navigation3` and `material3.adaptive:adaptive-navigation3` artifacts. Nav3 API patterns themselves live in the `navigation-3` skill.

### ViewModel and lifecycle

- Put ViewModels in `commonMain` using the multiplatform `lifecycle-viewmodel-compose`; obtain them with `viewModel { … }`, scoped to the navigation entry.
- Compose Multiplatform provides a common `LifecycleOwner`; rely on it instead of Android `Lifecycle` directly in common code.
- Inject dependencies with a KMP DI framework (Koin or Metro); do not pass ViewModels through navigation.

### Platform-specific behavior

- Account for differing software-keyboard insets and safe areas (notably iOS); test that the keyboard does not cover inputs.
- Desktop has no multitouch — do not rely on pinch/two-finger gestures there.
- iOS back gesture is added by Compose Multiplatform by default to match Android; desktop maps back to Esc.
- Text rendering is not pixel-identical across platforms — expect screenshot tests to differ per target.
- Hot reload and Compose previews are available for JVM/desktop; plan iteration accordingly.

### Share vs native

- Share the bulk of UI in common code; drop to native (SwiftUI/`UIView`, Android `View`) only for platform-idiomatic surfaces or capabilities Compose can't reach, bridged via `expect`/`actual`.

## Verify

- Shared composables, navigation, and ViewModels are in `commonMain`; `xxxMain` holds only entry points and platform capabilities.
- Common code uses `org.jetbrains.compose` / `org.jetbrains.androidx.*`, not Android-only `androidx.compose.*`.
- All assets resolve through the generated `Res`; no per-platform asset duplication.
- Routes are `@Serializable`, type-safe, and carry only minimal data; web binds to browser navigation.
- The app builds and mounts `App()` on every targeted platform; keyboard, gestures, and back behave correctly per platform.
