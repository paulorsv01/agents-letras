# Kotlin Multiplatform on AGP 9

AGP 9 changes the supported Android shape for Kotlin Multiplatform projects.
Do not keep `org.jetbrains.kotlin.multiplatform` in the same subproject as
`com.android.library` or `com.android.application`. Split the project so the
KMP code is a shared library and the Android app is a separate application
module that depends on it.

## Target layout

Prefer a split-module layout:

```text
<project>/
├── shared/       # KMP library: common, Android, iOS source sets
├── androidApp/   # Android application, depends on :shared
└── iosApp/       # Xcode project consuming the shared framework
```

`settings.gradle.kts` should include the Android-facing Gradle modules:

```kotlin
include(":shared", ":androidApp")
```

This replaces older layouts where one module tried to be both the Android app
and the multiplatform module.

## Shared KMP module

The shared module keeps the Kotlin Multiplatform plugin and uses the AGP 9
Android KMP library plugin:

```kotlin
plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.android.kmp.library)
}
```

Version catalog example:

```toml
[plugins]
android-kmp-library = { id = "com.android.kotlin.multiplatform.library", version.ref = "agp" }
kotlin-multiplatform = { id = "org.jetbrains.kotlin.multiplatform", version.ref = "kotlin" }
```

The Android target is configured inside `kotlin { android { ... } }`, not an
`android { ... }` block:

```kotlin
kotlin {
    applyDefaultHierarchyTemplate()

    android {
        namespace = "com.example.app.shared"
        compileSdk = 36
        minSdk = 26
        withHostTest {}
    }

    iosX64()
    iosArm64()
    iosSimulatorArm64()
}
```

Android-specific dependencies belong in `sourceSets.androidMain.dependencies`,
not in a top-level `dependencies { implementation(...) }` block:

```kotlin
kotlin {
    sourceSets {
        androidMain.dependencies {
            implementation("androidx.core:core-ktx:1.18.0")
        }
    }
}
```

Enable optional Android pieces explicitly:

```kotlin
kotlin {
    android {
        androidResources {
            enable = true
        }
        withJava()
        withHostTest {}
        withDeviceTest {
            instrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        }
    }
}
```

Only turn these on when the shared module actually needs them. The Android KMP
plugin keeps resources, Java compilation, and Android host/device tests disabled
by default to avoid unused build work.

`withHostTest {}` creates the `androidHostTest` source set and includes
`commonTest` by default. `withDeviceTest {}` creates `androidDeviceTest`, but
does not include `commonTest` by default; use `withDeviceTestBuilder { ... }`
when you need to customize its source set tree or configure the created test
component separately.

If the project exports an iOS framework, keep that in the shared module:

```kotlin
import org.jetbrains.kotlin.gradle.plugin.mpp.KotlinNativeTarget
import org.jetbrains.kotlin.gradle.plugin.mpp.apple.XCFramework

val xcf = XCFramework("shared")

kotlin {
    targets.withType<KotlinNativeTarget>().configureEach {
        binaries.framework {
            baseName = "shared"
            isStatic = true
            xcf.add(this)
        }
    }
}
```

## Android app module

The Android application module uses `com.android.application` only. Do not apply
`org.jetbrains.kotlin.android`; AGP 9 built-in Kotlin handles Android Kotlin
compilation.

```kotlin
plugins {
    alias(libs.plugins.android.application)
}

android {
    namespace = "com.example.app"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 26
        targetSdk = 36
    }
}

dependencies {
    implementation(project(":shared"))
}
```

Apply Compose compiler or other app plugins only when the app module actually
uses them. Keep shared business logic and Compose Multiplatform UI in
`shared/commonMain` unless Android-only APIs are required.

## Unsupported or different Android KMP features

The Android KMP plugin is a single-variant library plugin. It does not support
Android build types and product flavors inside the KMP module. If shared Android
code needs variants, native build integration, data binding, view binding, or
other `com.android.library`-specific features, put that code in a separate
Android library module and consume it from `shared/src/androidMain`.

Do not force the KMP module back onto `com.android.library` just to regain the
old DSL. That preserves technical debt AGP 10 is expected to remove.

## Source sets

With `applyDefaultHierarchyTemplate()`, the usual hierarchy is:

```text
commonMain
├── androidMain
└── appleMain
    └── iosMain
        ├── iosX64Main
        ├── iosArm64Main
        └── iosSimulatorArm64Main
```

Migration rule of thumb:

| Existing code | New location |
|---|---|
| Platform-neutral models, state, repositories, Flow/coroutine logic | `shared/src/commonMain` |
| Android framework APIs, Android resources, Context-dependent code | `shared/src/androidMain` or `androidApp` |
| Android unit tests from a legacy KMP library | `shared/src/androidHostTest` after enabling `withHostTest {}` |
| Android instrumented tests from a legacy KMP library | `shared/src/androidDeviceTest` after enabling `withDeviceTest {}` |
| iOS UIKit/Foundation interop | `shared/src/iosMain` |
| Activity, manifest, application id, signing, Play packaging | `androidApp` |

Use `expect` / `actual` for common APIs that need platform implementations.

## Compose Multiplatform

If the old project used a single `composeApp` module, split the concerns:

- shared composables live in `shared/commonMain`
- Android entry point calls the shared `App()` from `androidApp`
- iOS entry point exposes a `ComposeUIViewController` from `shared/iosMain`

Example iOS bridge:

```kotlin
fun MainViewController() = ComposeUIViewController { App() }
```

Kotlin and Compose Multiplatform versions must move together. Current
project versions must also respect the AGP, Gradle, Kotlin Multiplatform, and
Compose Multiplatform compatibility tables. Do not infer KMP-safe versions from
an Android-only project or scaffold template.

## Verification

After restructuring, run the general AGP checks plus at least one Android app
build and one shared iOS framework build:

```bash
./gradlew help
./gradlew :androidApp:assembleDebug
./gradlew :shared:testAndroidHostTest
./gradlew :shared:assembleXCFramework
```

For release-oriented projects, also verify:

```bash
./gradlew :androidApp:bundleRelease
./gradlew :shared:assembleSharedReleaseXCFramework
```

Use the task names that exist in the project. Some KMP setups expose
`assembleSharedXCFramework` or `assembleSharedReleaseXCFramework` depending on
how the `XCFramework` is named.

## Common failures

| Symptom | Fix |
|---|---|
| `com.android.kotlin.multiplatform.library plugin not found` | Use AGP 9+ and ensure `google()` is present in `pluginManagement.repositories`. |
| KMP module also applies `com.android.application` or `com.android.library` | Split into `shared` plus `androidApp`; use `com.android.kotlin.multiplatform.library` in `shared`. |
| `org.jetbrains.kotlin.android` error in the Android app module | Remove the Kotlin Android plugin; use AGP 9 built-in Kotlin. |
| Android resources in `shared/src/androidMain/res` are ignored | Enable `androidResources { enable = true }` in `kotlin.android`. |
| Java files under `shared/src/androidMain/java` do not compile | Enable `withJava()` in `kotlin.android`. |
| `shared/src/androidTest` or `shared/src/test` no longer runs | Move to `androidDeviceTest` or `androidHostTest` and enable the matching test component. |
| Compose compiler or Compose Multiplatform version errors | Align Kotlin and Compose Multiplatform versions from their compatibility matrix. |
| iOS framework task is missing | Ensure iOS targets exist and `binaries.framework` is configured in the shared module. |
