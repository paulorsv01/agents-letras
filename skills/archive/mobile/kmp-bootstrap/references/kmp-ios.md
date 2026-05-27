# iOS integration

How `iosApp/` consumes `:shared` and how to drive the simulator from the CLI.

## Config.xcconfig (Letras-style)

`iosApp/Configuration/Config.xcconfig` centralizes:

```
TEAM_ID=<Apple team ID — empty for simulator-only>
BUNDLE_ID=<reverse-DNS, must match androidApp applicationId or share a pattern>
APP_NAME=<display name>

DEVELOPMENT_TEAM=$(TEAM_ID)
PRODUCT_BUNDLE_IDENTIFIER=$(BUNDLE_ID)
PRODUCT_NAME=$(APP_NAME)

MARKETING_VERSION=<VERSION_NAME from version.env>
CURRENT_PROJECT_VERSION=<VERSION_CODE from version.env>
```

Xcode automatically consumes `DEVELOPMENT_TEAM`, `PRODUCT_BUNDLE_IDENTIFIER`, `PRODUCT_NAME`, `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION` — those are built-in build settings. The xcconfig wins over anything in `project.pbxproj` when both are set.

**Binding the xcconfig to the project** — the vendored `iosApp.xcodeproj` already points both Debug and Release configurations at `Configuration/Config.xcconfig`. If you create a new xcodeproj by hand, set it under `Project → Info → Configurations`.

## Version sync

`version.env` is the single source of truth. Propagate:
```
make sync-version
```
This rewrites `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` lines in `Config.xcconfig`. Don't edit those two in Xcode UI — your edit will be clobbered on the next `make sync-version`.

## Framework consumption

`:shared` produces a framework named `shared` (static). Xcode's Run Script build phase invokes:
```
./gradlew :shared:embedAndSignAppleFrameworkForXcode
```
This task:
- Picks the target (`iosSimulatorArm64`, `iosX64`, `iosArm64`) based on Xcode's active destination.
- Builds the framework at `shared/build/xcode-frameworks/<CONFIGURATION>/<SDK>/shared.framework`.
- Re-signs the framework with Xcode's code signing identity.

Swift imports the framework:
```swift
import shared
// ...
MainViewControllerKt.MainViewController()
```

Kotlin functions become static methods on a class named `<FileName>Kt`. So `fun MainViewController()` in `MainViewController.kt` → `MainViewControllerKt.MainViewController()` in Swift.

## Simulator and device CLI

List available simulators:
```
make ios-list
# or: scripts/ios_list.sh "iOS 18"
```

Build + install + launch with target selection:
```
make dev-ios               # any: booted simulator → physical device → fresh simulator
make run-ios-simulator     # pin to a simulator
make run-ios-device        # pin to a connected iPhone
# Underlying: scripts/ios_run.sh [--target any|simulator|device] [--derived-data <path>] [udid|name]
```

### Simulator path

```bash
xcrun simctl boot <UDID>               # start simulator
open -a Simulator                      # reveal UI
xcodebuild -workspace iosApp/iosApp.xcworkspace \
    -scheme iosApp -sdk iphonesimulator \
    -destination "id=<UDID>" \
    [-derivedDataPath <path>] build
xcrun simctl install <UDID> <path-to-.app>
xcrun simctl launch <UDID> <BUNDLE_ID>
```

### Device path

```bash
# Discover an attached iPhone (filtering placeholders)
xcodebuild -showdestinations -scheme iosApp \
    | awk '/platform:iOS,/ && /arch:/ && $0 !~ /placeholder/ { ... }'

xcodebuild -workspace iosApp/iosApp.xcworkspace \
    -scheme iosApp -sdk iphoneos \
    -destination "id=<DEVICE_ID>" build

xcrun devicectl device install app --device <DEVICE_ID> <path-to-.app>
xcrun devicectl device process launch --device <DEVICE_ID> --terminate-existing <BUNDLE_ID>
```

### Resolving the .app path reliably

`find $DERIVED -name '*.app'` picks the wrong artifact on multi-product schemes (extensions, watch apps). Parse `xcodebuild -showBuildSettings` instead:

```
TARGET_BUILD_DIR / WRAPPER_NAME (or FULL_PRODUCT_NAME if WRAPPER_NAME is missing)
```

This gives the canonical built `.app` for the active configuration + sdk + destination. `ios_run.sh` does this and uses the result both for `simctl install` and `devicectl install app`.

Stream app logs:
```
xcrun simctl spawn <UDID> log stream --predicate 'process == "<APP_NAME>"'
```

Open the Xcode UI for debugging:
```
make ios-open
```

## Release XCFramework

```
make xcframework
```
Output: `shared/build/XCFrameworks/release/shared.xcframework`.

Consumers (SPM package, CocoaPods spec, or a separate iOS app) reference it directly. For SPM export as a public library, see the upstream skill `kotlin-tooling-cocoapods-spm-migration`.

## iOS signing caveats

- Simulator builds don't need a team.
- Device builds need `DEVELOPMENT_TEAM` (from Config.xcconfig) + a matching provisioning profile (auto-managed by Xcode the first time you run on device).
- For CI/CD device builds + `.ipa` export, the pattern is:
  - `xcodebuild archive -archivePath Build.xcarchive`
  - `xcodebuild -exportArchive -archivePath Build.xcarchive -exportPath Build -exportOptionsPlist ExportOptions.plist`
  - This requires a provisioning profile + signing certificate and is out of scope for the bootstrap. It fits a follow-up skill (e.g. `kmp-ios-release`).
