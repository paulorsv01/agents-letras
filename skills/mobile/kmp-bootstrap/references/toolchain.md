# Toolchain

Generated projects target the current stable AGP 9 line and a stable Compose
Multiplatform release:

| Component | Default |
|---|---|
| JDK toolchain | 21 |
| Gradle wrapper | 9.4.1 |
| Android Gradle Plugin | 9.2.x |
| Kotlin | 2.3.x |
| Compose Multiplatform | 1.10.x |
| compileSdk / targetSdk | 36 |
| minSdk | 26 |
| iOS targets | `iosX64`, `iosArm64`, `iosSimulatorArm64` |

Source-of-truth links:

- AGP and required Gradle versions: https://developer.android.com/build/releases/about-agp
- Android KMP plugin: https://developer.android.com/kotlin/multiplatform/plugin
- Compose Multiplatform compatibility: https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-compatibility-and-versioning.html

When updating the template, update these together:

1. `assets/templates/scripts/bootstrap.sh`
2. `SKILL.md` defaults
3. `references/kmp-targets.md`
4. this file

Do not chase preview AGP, Kotlin, or Compose Multiplatform versions in bootstrap
defaults. Use stable releases unless the user explicitly asks for preview
tooling.
