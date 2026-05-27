# KMP Targets, Source Sets, expect/actual

## Targets bootstrapped
- `androidLibrary` (via `com.android.kotlin.multiplatform.library` in AGP 9)
- `iosX64` — Intel Mac simulator + Intel-era iPhones (legacy)
- `iosArm64` — physical iPhones
- `iosSimulatorArm64` — Apple Silicon Mac simulator

All iOS targets produce a static framework named `shared`, aggregated into a single `shared.xcframework` via `XCFramework("shared")`.

## Source set hierarchy
With `applyDefaultHierarchyTemplate()`, the hierarchy is inferred from declared targets:

```
commonMain
├── androidMain
└── appleMain
    └── iosMain
        ├── iosX64Main
        ├── iosArm64Main
        └── iosSimulatorArm64Main
```

`commonTest`, `androidHostTest`, `androidDeviceTest`, `iosTest`, etc. mirror this when the target enables those test components. Dependencies declared in a parent set are inherited by children.

## When to use each source set
| Code lives in | When |
|---|---|
| `commonMain` | Business logic, UI (Compose MP), models, Flow/Coroutine logic. Default. |
| `androidMain` | Android framework APIs (`android.*`, `androidx.*`), Context-dependent work. |
| `iosMain` | Apple frameworks (`platform.UIKit.*`, `platform.Foundation.*`), Objective-C interop. |
| `appleMain` | Logic shared across iOS + macOS + watchOS + tvOS. |
| `androidHostTest` | JVM-runnable tests for the Android KMP target. Enable with `withHostTest {}`. |
| `androidDeviceTest` | Device/emulator tests for the Android KMP target. Enable with `withDeviceTest {}` only when needed. |
| `commonTest` | Pure KMP unit tests using `kotlin.test`. |
| `iosTest` | Tests run on iOS simulator. |

## expect / actual

Declare a common-API stub; implement per platform.

`commonMain/Platform.kt`:
```kotlin
package <pkg>.shared

expect class Platform() {
    val name: String
}
```

`androidMain/Platform.android.kt`:
```kotlin
package <pkg>.shared

import android.os.Build

actual class Platform actual constructor() {
    actual val name: String = "Android ${Build.VERSION.SDK_INT}"
}
```

`iosMain/Platform.ios.kt`:
```kotlin
package <pkg>.shared

import platform.UIKit.UIDevice

actual class Platform actual constructor() {
    actual val name: String = UIDevice.currentDevice.systemName() + " " + UIDevice.currentDevice.systemVersion
}
```

## Compose Multiplatform entry points

**Common** (`commonMain/App.kt`):
```kotlin
@Composable fun App() { /* Material 3 UI */ }
```

**Android** (`androidApp/MainActivity.kt`):
```kotlin
setContent { App() }
```

**iOS** (`iosMain/MainViewController.kt`):
```kotlin
fun MainViewController() = ComposeUIViewController { App() }
```

Then `iosApp/ContentView.swift`:
```swift
struct ComposeView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        MainViewControllerKt.MainViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
```

## Version matrix (current bootstrap defaults)

| Component | Version | Notes |
|---|---|---|
| JDK | 21 | toolchain + source/target compatibility |
| Gradle | 9.4.1 | required by AGP 9.2 |
| AGP | 9.2.0 | `com.android.kotlin.multiplatform.library`; current stable AGP 9 line |
| Kotlin | 2.3.21 | drives compose-compiler plugin |
| Compose Multiplatform | 1.10.3 | JetBrains' Compose artifact (not androidx.compose); required for AGP 9 compatibility |
| min SDK | 26 | Android 8.0 |
| compile SDK | 36 | latest |
| iOS deployment target | defined in vendored `iosApp.xcodeproj` | adjust in Xcode → target settings |

Bumping Kotlin usually means checking Compose Multiplatform and the Compose
Compiler Gradle plugin together. Confirm the current pair at
https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-compatibility-and-versioning.html

Confirm AGP/Gradle compatibility at
https://developer.android.com/build/releases/about-agp
