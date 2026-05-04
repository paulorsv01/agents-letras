# Scaffold

## What `android create` gives you
Running `android create --name "$NAME" --minSdk $MIN -o $DIR empty-activity` produces:

```
$DIR/
├── app/
│   ├── build.gradle.kts      # Compose + Material3 + Nav3 + tests
│   └── src/
│       ├── main/
│       │   ├── AndroidManifest.xml
│       │   ├── java/
│       │   └── res/
│       ├── test/java/
│       └── androidTest/java/
├── build.gradle.kts           # root, plugins only
├── settings.gradle.kts        # foojay toolchain resolver
├── gradle/
│   ├── libs.versions.toml     # AGP 9.2.x, Kotlin 2.3.x, Compose BOM, Nav3
│   └── wrapper/
├── gradlew / gradlew.bat
├── gradle.properties
├── local.properties           # SDK path (gitignored)
└── .gitignore
```

## What the overlay adds
1. **`.editorconfig`** — ktlint rules.
2. **`.gitignore` extras** — keystores, `*.env.local`, build artifacts already covered.
3. **`.githooks/pre-commit`** — runs `ktlint --format` on staged `.kt` files.
4. **`agents/openai.yaml`** — created by `scripts/setup_codex_environment.sh` as the local Codex project interface metadata.
5. **`version.env`** — `VERSION_NAME`, `VERSION_CODE`, `BUILD_NUMBER`. Sourced from `app/build.gradle.kts`.
6. **`app/src/test/`** — `ExampleUnitTest.kt` (JUnit + MockK + Turbine + coroutines-test).
7. **`app/src/androidTest/`** — `ExampleInstrumentedTest.kt` (Compose UI test with `createAndroidComposeRule`).
8. **Gradle patches** — pin the wrapper to the AGP-compatible Gradle line, bump JDK to 21, pin AGP/Kotlin/Compose BOM, add ktlint plugin, MockK, Turbine to `libs.versions.toml` and `app/build.gradle.kts`.
9. **`gradle.properties` patch** — enable `org.gradle.configuration-cache=true` for faster repeat builds.
10. **Package refactor** — rename `com.example.<appname>` to the user-provided package.

Project-local `AGENTS.md` is now out of bootstrap scope. Use `agents-bootstrap` to create `AGENTS.md` + `CLAUDE.md` after scaffold when the repo should carry local agent instructions.

## What `bootstrap.sh` prompts for
- **Koin DI** (default: no). If yes:
  - Adds `io.insert-koin:koin-android` + `koin-androidx-compose` to `libs.versions.toml`.
  - Creates `app/src/main/java/<pkg>/di/AppModule.kt` with an empty module.
  - Patches `Application` class to start Koin in `onCreate`.
- **Multi-module split** (default: no). If yes:
  - Creates `:core` (pure Kotlin lib) and `:data` (Android lib) modules.
  - `include(":app", ":core", ":data")` in `settings.gradle.kts`.
  - `:app` depends on `:core` and `:data`; `:data` depends on `:core`.
  - Re-runs manifest merger sanity check.

## Post-bootstrap setup
After `git init`, `bootstrap.sh` runs `scripts/setup.sh`. That script:
- restores `core.hooksPath` to `.githooks`
- creates `agents/openai.yaml` if the project does not already have local Codex interface metadata

## Renaming the package
After bootstrap, if you want to change `com.example.foo` → `com.mydomain.foo`:
```bash
OLD=com.example.foo
NEW=com.mydomain.foo
# Move source dirs
git mv app/src/main/java/${OLD//./\/} app/src/main/java/${NEW//./\/}
git mv app/src/test/java/${OLD//./\/} app/src/test/java/${NEW//./\/}
git mv app/src/androidTest/java/${OLD//./\/} app/src/androidTest/java/${NEW//./\/}
# Replace in build + source files
grep -rl "$OLD" app/ | xargs sed -i '' "s/$OLD/$NEW/g"
```

Then rebuild with `make clean build`.

## When the overlay is stale
`android create` may evolve — if `android update` brings a new template version, compare the new output against the overlay:
```bash
rm -rf /tmp/android-probe
android create --name Probe -o /tmp/android-probe empty-activity
diff -r /tmp/android-probe <your project before overlay>
```
Adjust the overlay and patches in `bootstrap.sh` accordingly.
