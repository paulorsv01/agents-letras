# Testing (KMP)

Generated projects use fast Android-host verification by default and keep iOS
simulator tests explicit. This keeps the normal `make test` loop usable while
still making cross-platform checks available before commit or release.

| Target | Source set | Command | Runs where |
|---|---|---|---|
| Shared common logic | `shared/src/commonTest` | `./gradlew :shared:androidHostTest` | Host JVM through the Android KMP target |
| Android unit | `androidApp/src/test` | `./gradlew :androidApp:testDebugUnitTest` | Host JVM |
| iOS simulator | `shared/src/iosTest` (via hierarchy) | `./gradlew :shared:iosSimulatorArm64Test` (or `iosX64Test` on Intel) | iOS Simulator |
| Android instrumented app | `androidApp/src/androidTest` | `./gradlew :androidApp:connectedAndroidTest` | Device / emulator |

Makefile wraps:
- `make test` → `:shared:androidHostTest` + `:androidApp:testDebugUnitTest`
- `make ios-test` → `:shared:iosSimulatorArm64Test` or `iosX64Test` (auto-picks by `uname -m`)
- `make android-test` → `:androidApp:connectedAndroidTest`

## Android KMP host tests

The Android KMP plugin does not create host/device test components by default.
The bootstrap opts in to host tests in `shared/build.gradle.kts`:

```kotlin
kotlin {
    android {
        withHostTest {}
    }
}
```

Keep shared logic tests in `shared/src/commonTest`. They are inherited by the
Android host test target and can also run on iOS through `make ios-test`.

Only add `shared/src/androidHostTest` when the test itself needs Android JVM
APIs or Robolectric-style behavior.

## Common tests with `kotlin.test`

KMP's `kotlin.test` is the common-denominator API. Available in `commonTest`:
```kotlin
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
```

Example (shipped by overlay — `shared/src/commonTest/kotlin/<pkg>/shared/PlatformTest.kt`):
```kotlin
class PlatformTest {
    @Test
    fun platform_has_non_empty_name() {
        assertTrue(Platform().name.isNotBlank())
    }
}
```

### Turbine (Flow) + coroutines-test
Both are wired into `commonTest` dependencies. `Turbine` works on all KMP targets — including iOS:
```kotlin
import app.cash.turbine.test
import kotlinx.coroutines.test.runTest

class FlowTest {
    @Test fun emits_sequence() = runTest {
        myFlow.test {
            assertEquals(1, awaitItem())
            cancelAndIgnoreRemainingEvents()
        }
    }
}
```

### MockK
**JVM-only.** Use it in `androidApp` unit tests or `shared/src/androidHostTest`.
**Don't add it to `commonTest`** — it doesn't exist for Kotlin/Native.

For KMP-wide mocking, prefer:
- Hand-written fakes (recommended).
- `mokkery` plugin (experimental, KMP-compatible alternative to MockK).
- Keep business logic pure in `commonMain`; mock at the edges in platform-specific tests.

## Compose UI tests (iOS + Android)

Compose Multiplatform's UI test framework can run on both Android instrumented tests and iOS simulator. Dependency lives in `compose.uiTest` + `compose.uiTestJUnit4` (Android) / platform-specific entry points. This is slightly advanced — the bootstrap ships unit tests only; add UI tests when you have real screens.

Reference: https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-test.html

## Guidelines
- **Prefer `commonTest`** for platform-neutral logic. Run it through Android host tests in the tight loop and iOS tests before commit/release.
- **Push logic to `commonMain`** so `commonTest` covers it. Platform-specific tests only for what can't be abstracted.
- **MockK stays out of commonTest.** If you find yourself wanting to mock in common, either (a) write a fake, or (b) the interface is at the wrong layer.
- **Turbine > manual Flow collection.** Don't race on timing.
- **`iosSimulatorArm64Test` is slow to start** (needs simulator). Run `make test` in the tight loop; run `make ios-test` on commit/CI.
