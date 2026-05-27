# Packaging

Android has two artifact formats. Know which one you need.

## APK vs AAB

| | APK | AAB |
|---|---|---|
| **Extension** | `.apk` | `.aab` |
| **Purpose** | Direct install on device | Upload to Play Store |
| **Per-device splits** | No — ships everything | Yes — Play generates optimized APKs per device |
| **Install directly** | `adb install foo.apk` | ❌ requires `bundletool` to convert |
| **Side-loading / GitHub release** | ✅ use this | ❌ use APK or `bundletool build-apks` |
| **Gradle task** | `assembleDebug` / `assembleRelease` | `bundleDebug` / `bundleRelease` |

**Rule of thumb:**
- **Dev / CI / side-loading** → APK.
- **Play Store upload** → AAB.
- **GitHub release** → AAB (per user preference). Consumers can use `bundletool build-apks --bundle=foo.aab --output=foo.apks` then install the universal split.

## Gradle tasks

```
./gradlew assembleDebug          # app/build/outputs/apk/debug/app-debug.apk
./gradlew assembleRelease        # app/build/outputs/apk/release/app-release-unsigned.apk
./gradlew bundleRelease          # app/build/outputs/bundle/release/app-release.aab
adb install app/build/outputs/apk/debug/app-debug.apk
./gradlew installRelease         # install release APK (signed required)
```

Generated bootstrap scripts use `assembleDebug` + targeted `adb -s <serial> install -r`, not `installDebug`, so installs only hit the selected device.

`make build` → `assembleDebug`. `make release` → `bundleRelease` + sign. See `release.md`.

## Output sizes
Expect debug > release. R8 shrinking, resource optimization, and DEX compression typically cut 30-60%:
- Debug APK (no R8): ~8-15 MB for an empty Compose app.
- Release APK (R8 enabled): ~2-5 MB.
- Release AAB (per-device split on Play): 1-3 MB per device download.

Enable R8 minification in `app/build.gradle.kts` release buildType:
```kotlin
release {
    isMinifyEnabled = true
    isShrinkResources = true
    proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro",
    )
}
```

Bootstrap defaults to `isMinifyEnabled = false` so release builds succeed without R8 configuration. Turn it on when you're ready to tune rules (see `r8-analyzer` skill).

## Version info
`versionCode` (monotonic int) and `versionName` (semver string) live in `app/build.gradle.kts`. The overlay wires them to `version.env`:

```
VERSION_NAME=0.1.0
VERSION_CODE=1
```

Read in Gradle:
```kotlin
val versionProps = rootProject.file("version.env").readLines()
    .filter { "=" in it && !it.startsWith("#") }
    .associate { it.substringBefore("=") to it.substringAfter("=") }

defaultConfig {
    versionCode = versionProps["VERSION_CODE"]!!.toInt()
    versionName = versionProps["VERSION_NAME"]
}
```

Bump `VERSION_CODE` on every release — Play rejects uploads with same or lower code.

## Verifying the output
```bash
# APK contents
unzip -l app/build/outputs/apk/debug/app-debug.apk | head

# AAB contents
unzip -l app/build/outputs/bundle/release/app-release.aab | head

# Check manifest + signing
aapt dump badging app/build/outputs/apk/release/app-release.apk | head

# Check signing on AAB (needs jarsigner from JDK)
jarsigner -verify -verbose app/build/outputs/bundle/release/app-release.aab | tail -10
```
