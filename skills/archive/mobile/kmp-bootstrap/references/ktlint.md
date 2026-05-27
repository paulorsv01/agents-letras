# ktlint (KMP)

Same two-layer setup as `android-bootstrap`: Gradle plugin for CI/build, ktlint CLI for pre-commit. Only difference is that the plugin applies across **all KMP source sets** (commonMain, iosMain, androidMain, commonTest, iosTest, ...) automatically — no per-source-set config needed.

## Gradle plugin

Applied in root `build.gradle.kts` `subprojects { }`:
```kotlin
import org.jlleitschuh.gradle.ktlint.KtlintExtension

subprojects {
    apply(plugin = "org.jlleitschuh.gradle.ktlint")
    extensions.configure<KtlintExtension> {
        version.set("1.5.0")
        android.set(true)
        ignoreFailures.set(false)
        filter {
            exclude { it.file.path.contains("/build/") }
            exclude { it.file.path.contains("/generated/") }
        }
    }
}
```

Tasks generated per module:
- `:shared:ktlintCheck` / `:shared:ktlintFormat`
- `:androidApp:ktlintCheck` / `:androidApp:ktlintFormat`

Aggregate: `./gradlew ktlintCheck`, `./gradlew ktlintFormat` (or `make lint`, `make format`).

## Pre-commit hook (ktlint CLI)

Same shell hook as `android-bootstrap`. Installed into `.githooks/pre-commit` by the overlay, activated by `git config core.hooksPath .githooks`.

```sh
#!/bin/sh
set -e
STAGED=$(git diff --cached --name-only --diff-filter=ACMR -- '*.kt' '*.kts' || true)
[ -z "$STAGED" ] && exit 0
command -v ktlint >/dev/null || { echo "ktlint not installed — skipping" >&2; exit 0; }
echo "$STAGED" | xargs ktlint --format
echo "$STAGED" | xargs git add
```

Install ktlint CLI: `brew install ktlint`.

## `.editorconfig`

```
[*.{kt,kts}]
indent_style = space
indent_size = 4
max_line_length = 120
ktlint_standard = enabled
ktlint_code_style = ktlint_official
ij_kotlin_allow_trailing_comma = true
ij_kotlin_allow_trailing_comma_on_call_site = true
ij_kotlin_name_count_to_use_star_import = 2147483647
ij_kotlin_name_count_to_use_star_import_for_members = 2147483647
ij_kotlin_packages_to_use_import_on_demand = unset
ktlint_function_naming_ignore_when_annotated_with = Composable

[*.{swift,m,h}]
indent_style = space
indent_size = 4
```

Swift files aren't linted by ktlint — the section above only sets indent rules for the editor. Use `swiftformat` or `swiftlint` separately if you want Swift linting (out of scope for this bootstrap).

## Generated Kotlin sources

The `shared` framework's `MainViewControllerKt` Swift-facing export and some Compose compiler output land under `build/` and are auto-excluded by the `filter { exclude { ... } }` block above. If you add code generators (Apollo, Room, Ksp) that write under `build/generated/`, no further config needed.
