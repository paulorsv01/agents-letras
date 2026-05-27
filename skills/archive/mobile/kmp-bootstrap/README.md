# KMP Bootstrap

Local skill. Sibling to `android-bootstrap`, targets Kotlin Multiplatform projects (Android + iOS) following the AGP 9 full restructure layout.

## Purpose
Scaffold a KMP project with Compose Multiplatform UI, ktlint, pre-commit hooks, Android host tests for shared code, Android app unit tests, optional iOS simulator tests, Makefile-driven dev loop (Android + iOS), local Codex project setup via `make setup`, and AAB + XCFramework release — all driven from the CLI, no Android Studio or Xcode iteration required.

## Dependencies
- `android` CLI (`d.android.com/tools/agents`) — used for Android SDK + emulator.
- Android SDK emulator binary (`$ANDROID_SDK_ROOT/emulator/emulator` or equivalent) — used by generated `launch.sh` for reliable automation.
- ADB vendor keys in `~/.android` — generated Android scripts export `ADB_VENDOR_KEYS="$HOME/.android"` so emulator auth works in non-interactive shells too.
- JDK 21 (Temurin via SDKMAN: `sdk install java 21-tem`).
- Xcode + command-line tools (`xcode-select --install`) — for `xcrun simctl` and `xcodebuild`.
- `gh` CLI — for `make release` only (bootstrap itself has no network dependency).
- `ktlint` CLI (for pre-commit hook): `brew install ktlint`.
- `imagemagick` (for `build_icon.sh` — Android launcher icons): `brew install imagemagick`.

## Relationship to other skills
- `android-bootstrap` — use for pure Android projects without a shared module.
- `android-cli` — authoritative reference for `android *` commands.
- See `SKILL.md` → Related Skills for the full list.
