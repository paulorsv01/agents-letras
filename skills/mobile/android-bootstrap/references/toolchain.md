# Toolchain

Generated projects target the current stable AGP 9 line:

| Component | Default |
|---|---|
| JDK toolchain | 21 |
| Gradle wrapper | 9.4.1 |
| Android Gradle Plugin | 9.2.x |
| Kotlin | 2.3.x |
| Compose BOM | 2026.04.x |
| compileSdk / targetSdk | 36 |
| minSdk | 26 |

Source-of-truth links:

- AGP and required Gradle versions: https://developer.android.com/build/releases/about-agp
- AGP release notes: https://developer.android.com/build/releases/gradle-plugin
- Compose BOM: https://developer.android.com/develop/ui/compose/bom

When updating the template, update these together:

1. `assets/templates/scripts/bootstrap.sh`
2. `SKILL.md` defaults
3. `references/scaffold.md`
4. this file

Do not chase preview AGP, Kotlin, or Compose versions in bootstrap defaults.
Use stable releases unless the user explicitly asks for preview tooling.
