# Testing

Two test source sets, two runners.

## Layout
```
app/src/
├── test/java/<pkg>/          # JVM unit tests (no Android framework)
│   └── ExampleUnitTest.kt
└── androidTest/java/<pkg>/   # Instrumented tests (run on device/emulator)
    └── ExampleInstrumentedTest.kt
```

Commands:
- `./gradlew test` — runs all unit tests (fast, no device).
- `./gradlew connectedAndroidTest` — runs instrumented tests on connected device/emulator.
- `make test` / `make android-test` — same via Makefile.

## Unit tests — `app/src/test/`
**Stack:**
- **JUnit 4** (Android's default; JUnit 5 requires extra plugin, skip for bootstrap).
- **MockK** — idiomatic Kotlin mocking. Prefer over Mockito.
- **Turbine** — Flow testing. Assert over emitted values with suspendable collectors.
- **kotlinx-coroutines-test** — `runTest`, `StandardTestDispatcher`, `advanceUntilIdle`.

Dependencies (added to overlay):
```toml
[versions]
mockk = "1.14.7"
turbine = "1.2.1"

[libraries]
mockk = { module = "io.mockk:mockk", version.ref = "mockk" }
turbine = { module = "app.cash.turbine:turbine", version.ref = "turbine" }
```

In `app/build.gradle.kts`:
```kotlin
testImplementation(libs.mockk)
testImplementation(libs.turbine)
```

Example — `app/src/test/java/<pkg>/CounterViewModelTest.kt`:
```kotlin
package <pkg>

import app.cash.turbine.test
import io.mockk.coEvery
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test
import kotlin.test.assertEquals

@OptIn(ExperimentalCoroutinesApi::class)
class CounterViewModelTest {
    private val dispatcher = StandardTestDispatcher()

    @Before fun setUp() { Dispatchers.setMain(dispatcher) }
    @After fun tearDown() { Dispatchers.resetMain() }

    @Test
    fun `increment emits next value`() = runTest {
        val repo = mockk<CounterRepository>()
        coEvery { repo.current() } returns 0
        val vm = CounterViewModel(repo)

        vm.state.test {
            assertEquals(0, awaitItem())
            vm.increment()
            assertEquals(1, awaitItem())
            cancelAndIgnoreRemainingEvents()
        }
    }
}
```

## Instrumented tests — `app/src/androidTest/`
**Stack:**
- **androidx.test** — `@RunWith(AndroidJUnit4::class)`, `ApplicationProvider`.
- **Compose UI test** — `createAndroidComposeRule<MainActivity>()` for driving composables from tests.
- **Espresso** (included by default) — for legacy View interop.

Example — `app/src/androidTest/java/<pkg>/MainActivityTest.kt`:
```kotlin
package <pkg>

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import org.junit.Rule
import org.junit.Test

class MainActivityTest {
    @get:Rule val rule = createAndroidComposeRule<MainActivity>()

    @Test
    fun shows_greeting() {
        rule.onNodeWithText("Hello").assertIsDisplayed()
    }
}
```

## Guidelines
- **Unit over instrumented** — prefer `test/` for logic. Instrumented is slow and requires a device.
- **Test behavior, not trivial paths** — cover edge cases, error states, cancellation, concurrency.
- **Don't mock what you don't own** — prefer fakes for your own interfaces, mocks only for boundaries.
- **Test names describe behavior** — use backticks for readable names: `` `increment emits next value` ``.
- **Structure so failures are identifiable** — one assert per test when possible; Turbine's `awaitItem()` helps.
- **Flow tests: always use Turbine** — don't collect manually, you'll race on timing.

## What the overlay ships
- `ExampleUnitTest.kt` — a self-contained test showing MockK + Turbine + coroutines-test.
- `ExampleInstrumentedTest.kt` — Compose UI test hitting the bootstrapped `MainActivity`.

These are replaceable starters — delete them when you add real tests.
