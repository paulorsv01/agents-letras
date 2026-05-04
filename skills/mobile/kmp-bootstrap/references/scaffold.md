# Scaffold

## Output layout (AGP 9 full restructure)
```
<project>/
├── shared/                        # pure KMP library
│   ├── build.gradle.kts
│   └── src/
│       ├── commonMain/kotlin/<pkg>/shared/    # App.kt, Platform.kt (expect)
│       ├── commonTest/kotlin/<pkg>/shared/
│       ├── androidMain/kotlin/<pkg>/shared/   # Platform.android.kt (actual)
│       └── iosMain/kotlin/<pkg>/shared/       # Platform.ios.kt, MainViewController.kt
├── androidApp/                    # Android application module, depends on :shared
│   ├── build.gradle.kts
│   └── src/main/{java,res}/
├── iosApp/                        # Xcode project consuming :shared as framework
│   ├── iosApp.xcodeproj/
│   ├── Configuration/Config.xcconfig
│   └── iosApp/                    # Swift sources (iOSApp.swift, ContentView.swift) + Assets.xcassets
├── gradle/
│   ├── libs.versions.toml         # AGP 9.2.x, Kotlin 2.3.x, Compose MP
│   └── wrapper/
├── version.env                    # VERSION_NAME / VERSION_CODE (source of truth)
├── Makefile
├── scripts/
├── settings.gradle.kts            # include :shared, :androidApp
├── build.gradle.kts               # plugins apply false + ktlint subprojects
├── .editorconfig / .gitignore / .githooks/pre-commit
```

## How `bootstrap.sh` builds this
1. Calls `android create` solely to obtain a working Gradle wrapper (9.1.0) and `gradle/` dir, then deletes the generated `app/` — we rebuild from scratch.
2. Copies overlay (`.editorconfig`, `.gitignore.extras` appended, `.githooks/pre-commit`, `version.env`).
3. Bumps `gradle.properties` heap to `-Xmx4096m` (Kotlin/Native XCFramework linker needs it).
4. Copies `Makefile` and `scripts/` into the project root.
5. Overwrites `gradle/libs.versions.toml` with a KMP-oriented catalog.
6. Writes `settings.gradle.kts` including `:shared` and `:androidApp`.
7. Writes `build.gradle.kts` (root) with all plugins `apply false` + ktlint configuration for all subprojects.
8. Writes `shared/build.gradle.kts` using the AGP 9 shape:
   ```kotlin
   plugins {
       alias(libs.plugins.kotlin.multiplatform)
       alias(libs.plugins.android.kmp.library)   // com.android.kotlin.multiplatform.library
       alias(libs.plugins.compose.multiplatform)
       alias(libs.plugins.compose.compiler)
   }
   val xcf = XCFramework("shared")
   kotlin {
        android { namespace = "..."; compileSdk = 36; minSdk = 26; withHostTest {}; ... }
       iosX64(); iosArm64(); iosSimulatorArm64()
       targets.withType<KotlinNativeTarget>().configureEach {
           binaries.framework { baseName = "shared"; isStatic = true; xcf.add(this) }
       }
       sourceSets {
           commonMain.dependencies { compose.runtime; compose.ui; ... }
           commonTest.dependencies { kotlin("test"); turbine; kotlinx.coroutines.test }
       }
   }
   ```
9. Writes `androidApp/build.gradle.kts` with `com.android.application`, JDK 21, signing config reading `.signing.env`, version config reading `version.env`, `implementation(project(":shared"))`. AGP 9 bundles Kotlin support so no `kotlin-android` plugin.
10. **iosApp/** — copied from the vendored skeleton under `assets/templates/iosApp/`. No network fetch. Then writes `Configuration/Config.xcconfig` with the Letras-style wiring (`TEAM_ID`, `BUNDLE_ID`, `APP_NAME`, `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`).
11. Optional Koin scaffolding: adds `koin-core` to commonMain, `koin-android` to androidMain, `koin-compose` to androidApp; creates `<pkg>.shared.di.sharedModule` and an Android `Application` class that starts Koin. iOS initialization is intentionally left to the app entry point when real dependencies exist.
12. `git init`, then `scripts/setup.sh` restores `core.hooksPath` and `agents/openai.yaml`.

Project-local `AGENTS.md` is now out of bootstrap scope. Use `agents-bootstrap` to create `AGENTS.md` + `CLAUDE.md` after scaffold when the repo should carry local agent instructions.

## Prompts
- **Koin DI** (default: no). Wires `koin-core` common + `koin-android` + `koin-compose` + a `sharedModule` stub + an Android Application class that calls `startKoin`. iOS startup is not generated until a real shared dependency graph needs it.
- **DEVELOPMENT_TEAM** (optional). Written into `Config.xcconfig`. Leave empty for simulator-only iteration.

## Vendored iOS skeleton
`assets/templates/iosApp/` ships the whole iOS project: `iosApp.xcodeproj`, Swift sources (`iOSApp.swift`, `ContentView.swift`), Info.plist, Assets.xcassets (including 1024×1024 AppIcon), and `Configuration/Config.xcconfig`. It was captured once from `JetBrains/compose-multiplatform-template` and sanitized:
- ContentView calls `MainViewControllerKt.MainViewController()` (was `Main_iosKt.MainViewController()`).
- Display-only "My application.app" path replaced with `iosApp.app`.
- Target-level `DEVELOPMENT_TEAM`, `PRODUCT_BUNDLE_IDENTIFIER`, `PRODUCT_NAME` removed — `Config.xcconfig` owns identity exclusively. The upstream template hardcodes `PRODUCT_BUNDLE_IDENTIFIER = "${BUNDLE_ID}${TEAM_ID}"` in the target, which corrupts the bundle id when `TEAM_ID` is non-empty.
- `baseConfigurationReference = Config.xcconfig` added to both target build configs so the xcconfig resolves at every level.

Bootstrap does `cp -R` + overwrite `Config.xcconfig` — no dependency on `gh`, `xcodegen`, or network at bootstrap time.

## Post-bootstrap setup
`scripts/setup.sh` is the local repair target behind `make setup`. It:
- restores `core.hooksPath` to `.githooks`
- creates `agents/openai.yaml` if the project does not already have local Codex interface metadata

### Refreshing the vendored skeleton
If you ever need to re-capture (template upstream adds something you want):
```bash
gh repo clone JetBrains/compose-multiplatform-template /tmp/tpl -- --depth 1
rm -rf ~/Developer/agents/skills/kmp-bootstrap/assets/templates/iosApp
cp -R /tmp/tpl/iosApp ~/Developer/agents/skills/kmp-bootstrap/assets/templates/iosApp
SKEL=~/Developer/agents/skills/kmp-bootstrap/assets/templates/iosApp
# Swift entry point matches our Kotlin symbol:
sed -i '' 's/Main_iosKt\.MainViewController/MainViewControllerKt.MainViewController/g' "$SKEL/iosApp/ContentView.swift"
# Display label for the .app product:
sed -i '' 's|"My application\.app"|iosApp.app|g; s|/\* My application\.app \*/|/* iosApp.app */|g' "$SKEL/iosApp.xcodeproj/project.pbxproj"
# Strip target-level identity keys — xcconfig owns them. Also add baseConfigurationReference
# to both target build configs. Easiest: open the pbxproj and replicate the current diff from
# git (the five lines per Debug/Release config). plutil -lint after.
plutil -lint "$SKEL/iosApp.xcodeproj/project.pbxproj"
```

## Renaming the package after the fact
```bash
OLD=com.example.foo
NEW=com.mydomain.foo
# Kotlin + Swift
grep -rl "$OLD" shared/ androidApp/ iosApp/ | xargs sed -i '' "s/$OLD/$NEW/g"
# Move kotlin source dirs
for root in shared/src/commonMain/kotlin shared/src/iosMain/kotlin shared/src/androidMain/kotlin androidApp/src/main/java; do
    [ -d "$root/${OLD//./\/}" ] || continue
    mkdir -p "$root/${NEW//./\/}"
    mv "$root/${OLD//./\/}"/* "$root/${NEW//./\/}/"
done
# Update Config.xcconfig BUNDLE_ID
sed -i '' "s/^BUNDLE_ID=.*/BUNDLE_ID=$NEW/" iosApp/Configuration/Config.xcconfig
./gradlew clean
```
