# Release (KMP)

`make release` produces and publishes:
1. **Android AAB** (`:androidApp:bundleRelease`) — signed with the release keystore.
2. **iOS XCFramework** (`:shared:assembleSharedReleaseXCFramework`) — zipped.

Both uploaded to a GitHub release tagged `v<VERSION_NAME>` via `gh release create`.

## One-time Android signing setup

```bash
make setup-signing
# Creates: keystores/debug.keystore, keystores/release.keystore, .signing.env (mode 600)
```

Back up `keystores/release.keystore` off-machine. Lose it → cannot update the Play Store listing.

**iOS signing** is separate — set `TEAM_ID` in `iosApp/Configuration/Config.xcconfig`. Simulator-only iteration doesn't need a team.

## Release flow (`scripts/make_release.sh`)

```
1. Read VERSION_NAME, VERSION_CODE from version.env.
2. Abort if git tree is dirty.
3. Abort if tag v$VERSION_NAME already exists.
4. ./gradlew clean :androidApp:bundleRelease
5. scripts/sync_version.sh  (propagate to Config.xcconfig)
6. scripts/build_xcframework.sh  (→ shared.xcframework)
7. jarsigner -verify on the AAB.
8. Zip XCFramework for gh upload.
9. git tag -a v$VERSION_NAME, push.
10. gh release create v$VERSION_NAME AAB XCFramework.zip
```

## Bumping versions

Edit `version.env`:
```
VERSION_NAME=0.2.0
VERSION_CODE=2
```

Commit. Run `make release`. The script handles Android build versioning and iOS `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` propagation.

## Consumers of the GitHub release

- **AAB**: upload to Play Console manually (Production / Internal / Closed track). Automating this needs the Play Publisher plugin — follow-up skill.
- **XCFramework.zip**: third-party iOS app maintainers download and drag into their Xcode project, or reference via a manually-maintained SPM `Package.swift`.
- **Direct Android install**: AAB can't be side-loaded. Add a universal APK to the release if you need this:
  ```bash
  bundletool build-apks --bundle=androidApp-release.aab --output=app.apks --mode=universal
  unzip -p app.apks universal.apk > androidApp-release-universal.apk
  gh release upload v$VERSION_NAME androidApp-release-universal.apk
  ```

## Out of bootstrap scope (follow-ups)

- **`.ipa` export + TestFlight upload**: requires Apple provisioning profile + App Store Connect API key. Recipe lives in a future `kmp-ios-release` skill.
- **Play Publisher plugin**: automate AAB upload to Play Console track. Future `play-publisher` skill.
- **SPM package export**: publishes `shared.xcframework` as an SPM library. See `kotlin-tooling-cocoapods-spm-migration` skill.
- **Notarization / stapling**: macOS concepts, not applicable to iOS .ipa distribution.

## Common failures

See SKILL.md → "Common Failures" for keystore issues, simulator boot problems, missing `DEVELOPMENT_TEAM`, etc.
