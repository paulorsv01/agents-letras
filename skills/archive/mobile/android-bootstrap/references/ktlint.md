# ktlint

Two layers:

## 1. Gradle plugin (build / CI)
`org.jlleitschuh.gradle.ktlint` runs inside the build. Used by CI, `make lint`, `make format`.

Added to `gradle/libs.versions.toml`:
```toml
[versions]
ktlint = "12.1.1"
ktlintEngine = "1.5.0"

[plugins]
ktlint = { id = "org.jlleitschuh.gradle.ktlint", version.ref = "ktlint" }
```

Applied in root `build.gradle.kts`:
```kotlin
plugins {
  alias(libs.plugins.ktlint) apply false
}

subprojects {
  apply(plugin = "org.jlleitschuh.gradle.ktlint")

  configure<org.jlleitschuh.gradle.ktlint.KtlintExtension> {
    version.set(libs.versions.ktlintEngine.get())
    android.set(true)
    ignoreFailures.set(false)
    reporters {
      reporter(org.jlleitschuh.gradle.ktlint.reporter.ReporterType.PLAIN)
      reporter(org.jlleitschuh.gradle.ktlint.reporter.ReporterType.CHECKSTYLE)
    }
    filter {
      exclude { it.file.path.contains("/build/") }
      exclude { it.file.path.contains("/generated/") }
    }
  }
}
```

Tasks:
- `./gradlew ktlintCheck` — fail on violations (CI, `make lint`).
- `./gradlew ktlintFormat` — auto-fix in place (`make format`).

## 2. ktlint CLI (pre-commit hook)
The Gradle plugin is too slow for pre-commit (JVM startup + daemon). Use the ktlint CLI directly.

Install once per machine:
```bash
brew install ktlint
```

Hook at `.githooks/pre-commit` (delivered by overlay, activated by `git config core.hooksPath .githooks`):
```sh
#!/bin/sh
set -e
STAGED=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.kts?$' || true)
[ -z "$STAGED" ] && exit 0
if ! command -v ktlint >/dev/null 2>&1; then
  echo "ktlint not installed — skipping pre-commit lint. brew install ktlint" >&2
  exit 0
fi
echo "$STAGED" | xargs ktlint --format
echo "$STAGED" | xargs git add
```

The hook formats staged Kotlin files in place and re-stages them. If ktlint isn't installed it warns and skips (doesn't block the commit).

## `.editorconfig`
Both the Gradle plugin and the CLI honor `.editorconfig`. Delivered overlay:
```
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

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
```

## Disabling specific rules
Per-project rule override in `.editorconfig`:
```
[*.{kt,kts}]
ktlint_standard_no-wildcard-imports = disabled
ktlint_standard_filename = disabled
```

Full rule reference: https://pinterest.github.io/ktlint/latest/rules/standard/
