# Release

End-to-end: create keystore → configure signing → bundle → sign → publish.

## One-time: keystore creation

```bash
scripts/setup_signing.sh
```

Generates two keystores in `keystores/` (gitignored):

- `keystores/debug.keystore` — used for debug side-loads (`adb install`). Replaces the default `~/.android/debug.keystore` so everyone on the team shares signature (same `applicationId` install target).
- `keystores/release.keystore` — your release identity. **Back this up off-machine**. Lose it and you cannot update your Play Store listing — period.

Keystore params the script asks for interactively:
- Storepass, keypass (use a password manager).
- CN (common name), OU, O, L, ST, C.
- Alias (default: `release`).
- Validity: 25 years (Play requires at least that much remaining).

Stored as env vars for the signing config — write them to `.signing.env` (gitignored):
```
KEYSTORE_PATH=keystores/release.keystore
KEYSTORE_PASSWORD=...
KEY_ALIAS=release
KEY_PASSWORD=...
```

## Signing config in Gradle

`app/build.gradle.kts` reads `.signing.env` for release builds:
```kotlin
val signingEnv = rootProject.file(".signing.env").takeIf { it.exists() }?.readLines()
    ?.filter { "=" in it && !it.startsWith("#") }
    ?.associate { it.substringBefore("=") to it.substringAfter("=") }
    ?: emptyMap()

android {
    signingConfigs {
        create("release") {
            if (signingEnv.isNotEmpty()) {
                storeFile = rootProject.file(signingEnv["KEYSTORE_PATH"]!!)
                storePassword = signingEnv["KEYSTORE_PASSWORD"]
                keyAlias = signingEnv["KEY_ALIAS"]
                keyPassword = signingEnv["KEY_PASSWORD"]
            }
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // ...
        }
    }
}
```

If `.signing.env` is missing, release builds still succeed but produce unsigned artifacts — useful for CI branches that don't have the secret.

## Release flow

```bash
make release
```

Which runs `scripts/make_release.sh`:

1. Reads `version.env` → `VERSION_NAME`, `VERSION_CODE`.
2. Confirms git tree is clean (aborts otherwise — release must be reproducible).
3. `./gradlew clean bundleRelease` — produces signed AAB at `app/build/outputs/bundle/release/app-release.aab`.
4. Verifies signature with `jarsigner -verify`.
5. Creates git tag `v${VERSION_NAME}`.
6. `gh release create v${VERSION_NAME} app-release.aab --generate-notes`.
7. Prints Play Console upload URL reminder.

## Bumping versions

Edit `version.env`:
```
VERSION_NAME=0.2.0
VERSION_CODE=2
```

Commit. `make release` picks it up. **Always bump `VERSION_CODE`** — Play refuses uploads with equal or lower codes.

## GitHub release consumers
The AAB can't be installed directly. Consumers need `bundletool`:
```bash
bundletool build-apks --bundle=app-release.aab --output=app.apks --mode=universal
bundletool install-apks --apks=app.apks
```

If you want a turnkey install for non-Play users, add a universal APK to the release:
```bash
# In make_release.sh, additionally:
bundletool build-apks --bundle=app-release.aab --output=app.apks --mode=universal
unzip -p app.apks universal.apk > app-release-universal.apk
gh release upload v${VERSION_NAME} app-release-universal.apk
```

## Play Store upload
Manual for now (future skill: Play Publisher plugin). Console → Release → Create new release → upload `app-release.aab` → pick track (internal/closed/open/production).

## Common failures
See `SKILL.md` → "Common Failures" for keystore tampering, insufficient storage, etc.
