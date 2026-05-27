# Packaging (KMP)

Three artifacts. Pick based on who consumes.

| Target | Task | Output | Used by |
|---|---|---|---|
| Android APK (debug) | `:androidApp:assembleDebug` | `androidApp/build/outputs/apk/debug/androidApp-debug.apk` | `adb install`, side-loading |
| Android APK (release) | `:androidApp:assembleRelease` | `androidApp/build/outputs/apk/release/androidApp-release.apk` | GitHub release, direct install |
| Android AAB (release) | `:androidApp:bundleRelease` | `androidApp/build/outputs/bundle/release/androidApp-release.aab` | Play Store |
| iOS XCFramework (release) | `:shared:assembleSharedReleaseXCFramework` | `shared/build/XCFrameworks/release/shared.xcframework/` | Xcode projects, SPM packages, CocoaPods |
| iOS app (.app) | Via `xcodebuild` | `build/DerivedData/.../iosApp.app` | `xcrun simctl install` |
| iOS `.ipa` | Via `xcodebuild archive + -exportArchive` | `build/Export/iosApp.ipa` | TestFlight, ad-hoc distribution — **out of bootstrap scope** |

Bootstrap's `make release` ships:
- **AAB** for the Play Store.
- **shared.xcframework** (zipped) for iOS consumers.

## Version sync

Both Android and iOS read from `version.env`. Android reads it at Gradle configuration time; iOS via `make sync-version` propagating to `Config.xcconfig`:

```
version.env:
  VERSION_NAME=0.2.0          → Android versionName, iOS MARKETING_VERSION
  VERSION_CODE=5              → Android versionCode, iOS CURRENT_PROJECT_VERSION
```

Bump the file, commit, release. Always increase `VERSION_CODE` — Play rejects equal-or-lower codes.

## R8 / minification

Disabled by default in bootstrap (`isMinifyEnabled = false`). Enable when you're ready to tune keep rules:
```kotlin
release {
    isMinifyEnabled = true
    isShrinkResources = true
    proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
}
```

KMP shared library has no native-side R8 equivalent — Kotlin/Native strips dead code during framework compilation (via LLVM). The release XCFramework is already optimized.

## Output size

Rough ranges for an empty Compose Multiplatform shell:
| Artifact | Debug | Release (no R8) | Release (R8) |
|---|---|---|---|
| Android APK | 12-18 MB | 8-12 MB | 3-5 MB |
| Android AAB | — | 5-8 MB | 2-4 MB (per-device on Play) |
| iOS framework (sim) | 25-40 MB | 8-15 MB | — |
| shared.xcframework (all iOS targets) | — | 25-50 MB | — |

iOS framework is much larger than Android because Kotlin/Native emits a full runtime per-target. The XCFramework bundles all iOS slices; Xcode strips unused ones at app-archive time.

## Verifying artifacts

```bash
# APK + AAB manifest
aapt dump badging androidApp/build/outputs/apk/release/androidApp-release.apk | head
unzip -l androidApp/build/outputs/bundle/release/androidApp-release.aab | head

# Signature
jarsigner -verify -verbose androidApp/build/outputs/bundle/release/androidApp-release.aab | tail -5

# XCFramework structure
ls shared/build/XCFrameworks/release/shared.xcframework/
# ios-arm64/     — physical device
# ios-arm64_x86_64-simulator/  — simulator (fat)
# Info.plist
```

## Consuming the XCFramework in an external Xcode project

Drag `shared.xcframework` into the project, or reference via SPM if you export the framework as an SPM package (see `kotlin-tooling-cocoapods-spm-migration` skill).

Swift import — same as the in-repo `iosApp/`:
```swift
import shared
let name = Platform().name
```
