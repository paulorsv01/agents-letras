# Android Bootstrap

Local skill. Mirrors the structure of `macos-spm-app-packaging` for Android projects, built on top of the `android` CLI.

## Purpose
Scaffold a Kotlin + Jetpack Compose Android app without Android Studio, with ktlint, pre-commit hooks, test scaffolding (JUnit + MockK + Turbine + Compose UI), a Makefile-driven dev loop, current AGP-compatible Gradle wrapper pinning, Gradle configuration cache enabled by default, local Codex project setup via `make setup`, and AAB signing/release.

## Dependencies
- `android` CLI (`d.android.com/tools/agents`) — used by `bootstrap.sh` and for AVD discovery.
- Android SDK emulator binary (`$ANDROID_SDK_ROOT/emulator/emulator` or equivalent) — used by generated `launch.sh` for reliable automation.
- ADB vendor keys in `~/.android` — generated scripts export `ADB_VENDOR_KEYS="$HOME/.android"` so emulator auth works in non-interactive shells too.
- JDK 21 (Temurin via SDKMAN recommended: `sdk install java 21-tem`).
- `gh` CLI (for `make release`).
- `ktlint` CLI (for pre-commit hook): `brew install ktlint`.
- `imagemagick` (for `build_icon.sh`): `brew install imagemagick`.

## Relationship to other skills
- `android-cli` — authoritative reference for `android *` commands. This skill wraps a few of them (`create`, `emulator`, `run`) and adds project scaffolding.
- See `SKILL.md` for the full list of related skills.
